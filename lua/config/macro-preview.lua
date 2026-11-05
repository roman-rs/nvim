local M = {}
local preview_delay = 800
local shared = {}
local revision = 0
local uv = vim.uv
local inspecting = false

-- Cross-buffer caches are short-lived and invalidated by source edits. File stamps
-- also catch external changes before cached declarations are reused.
local function stamp(buf)
  if not vim.api.nvim_buf_is_valid(buf) then return end
  local file = uv.fs_stat(vim.api.nvim_buf_get_name(buf))
  return table.concat({ vim.api.nvim_buf_get_changedtick(buf), file and file.size or 0,
    file and file.mtime.sec or 0, file and file.mtime.nsec or 0 }, ":")
end

local function cache_get(cache, key)
  local entry = cache[key]
  if not entry or entry.revision ~= revision or entry.expires < uv.now() then return end
  for buf, version in pairs(entry.dependencies) do
    if stamp(buf) ~= version then cache[key] = nil; return end
  end
  return entry
end

local function cache_put(cache, key, value, dependencies, ttl)
  cache[key] = { value = vim.deepcopy(value), dependencies = vim.deepcopy(dependencies),
    revision = revision, expires = uv.now() + (ttl or 10000) }
  -- Bound memory even in long sessions traversing many source files.
  local count = 0
  for _ in pairs(cache) do count = count + 1 end
  if count > 256 then
    for old_key in pairs(cache) do if old_key ~= key then cache[old_key] = nil end end
  end
end

local group = vim.api.nvim_create_augroup("MacroPreviewCache", { clear = true })
vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "BufWritePost", "FileChangedShellPost" }, {
  group = group, callback = function() revision = revision + 1 end,
})
vim.api.nvim_create_autocmd("BufEnter", {
  group = group, callback = function(event)
    if inspecting or not vim.b[event.buf].macro_preview_inspection then return end
    vim.b[event.buf].macro_preview_inspection = nil
    vim.bo[event.buf].buflisted = true
    vim.bo[event.buf].swapfile = true
    local ok, parser = pcall(vim.treesitter.get_parser, event.buf)
    if ok and parser then vim.treesitter.start(event.buf, parser:lang()) end
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = event.buf, name = "clangd" })) do
      M.attach(client, event.buf)
    end
  end,
})

local function inspection_buffer(uri)
  local buf = vim.uri_to_bufnr(uri)
  if not vim.api.nvim_buf_is_loaded(buf) then
    vim.b[buf].macro_preview_inspection = true
    vim.bo[buf].buflisted = false
    vim.bo[buf].swapfile = false
    inspecting = true
    local loaded = pcall(vim.fn.bufload, buf)
    inspecting = false
    if not loaded then return end
  end
  return buf
end

-- clangd hover contains compiler-expanded tokens, including nested macros.
local function macro_contents(result)
  if not result or not result.contents then return end
  local lines = vim.lsp.util.convert_input_to_markdown_lines(result.contents)
  local text = table.concat(lines, "\n")
  local name = text:match("### macro `([^`]+)`") or text:match("#define%s+([%w_]+)")
  if not name then return end

  local code, in_code = {}, false
  for _, line in ipairs(lines) do
    if line:match("^```") then
      in_code = not in_code
    elseif in_code then
      code[#code + 1] = line
    end
  end
  local expanded
  for i, line in ipairs(code) do
    if line:match("^// Expands to") then expanded = i + 1; break end
  end
  if expanded then
    local expansion = vim.list_slice(code, expanded)
    if #expansion == 0 then expansion = { "// Expands to no tokens." } end
    return { name = name, lines = expansion, expanded = true }
  end
  if #code == 0 then code = { "// No macro definition returned by clangd." } end
  table.insert(code, 1, "// clangd returned a definition without expansion tokens.")
  return { name = name, lines = code, expanded = false }
end

-- Walk parsed calls rather than guessing parentheses inside strings/comments.
local function enclosing_calls(bufnr, cursor)
  local parsed = pcall(function() vim.treesitter.get_parser(bufnr):parse() end)
  if not parsed then return {} end
  local ok, node = pcall(vim.treesitter.get_node, {
    bufnr = bufnr, pos = { cursor[1] - 1, cursor[2] }, ignore_injections = true,
  })
  if not ok then return {} end
  local calls = {}
  while node and #calls < 8 do
    if node:type() == "call_expression" then
      local callee = node:field("function")[1]
      if callee and callee:type() == "identifier" then
        local row, col = callee:start()
        -- The hovered macro's own call is already covered by the first request.
        local end_row, end_col = callee:end_()
        if cursor[1] - 1 ~= row or cursor[2] < col
            or cursor[1] - 1 ~= end_row or cursor[2] >= end_col then
          calls[#calls + 1] = { row = row, col = col }
        end
      end
    end
    node = node:parent()
  end
  return calls
end

local function invocation_end(bufnr, row, col)
  local depth, quote, block_comment, started = 0, nil, false, false
  local lines = vim.api.nvim_buf_get_lines(bufnr, row, math.min(row + 200, vim.api.nvim_buf_line_count(bufnr)), false)
  for index, line in ipairs(lines) do
    local i = index == 1 and col + 1 or 1
    while i <= #line do
      local char, pair = line:sub(i, i), line:sub(i, i + 1)
      if block_comment then
        if pair == "*/" then block_comment = false; i = i + 1 end
      elseif quote then
        if char == "\\" then i = i + 1 elseif char == quote then quote = nil end
      elseif pair == "//" then
        break
      elseif pair == "/*" then
        block_comment = true; i = i + 1
      elseif char == '"' or char == "'" then
        quote = char
      elseif char == "(" then
        depth = depth + 1; started = true
      elseif char == ")" and started then
        depth = depth - 1
        if depth == 0 then return row + index - 1, i end
      end
      i = i + 1
    end
  end
end

local function generated_declaration(bufnr, position, encoding)
  local line = vim.api.nvim_buf_get_lines(bufnr, position.line, position.line + 1, false)[1]
  if not line then return end
  local col = vim.str_byteindex(line, encoding, position.character, false)
  local ok, node = pcall(function()
    vim.treesitter.get_parser(bufnr):parse()
    return vim.treesitter.get_node({ bufnr = bufnr, pos = { position.line, col } })
  end)
  if not ok then return end
  local invocation
  while node and node:type() ~= "translation_unit" do
    if node:type() == "macro_type_specifier" or node:type() == "call_expression" then
      invocation = node
    elseif node:type() == "declaration" then
      if not invocation then return end
      local callee = invocation:field(invocation:type() == "macro_type_specifier" and "name" or "function")[1]
      if not callee or callee:type() ~= "identifier" then return end
      local row, start_col = callee:start()
      local sr, sc = node:start()
      local ir, ic = invocation:start()
      local jr, jc = invocation_end(bufnr, row, start_col)
      if not jr then return end
      -- Macro-heavy files can confuse the C parser into merging later declarations.
      -- Only retain the immediate terminator, never unrelated trailing source.
      local suffix = table.concat(vim.api.nvim_buf_get_lines(bufnr, jr,
        math.min(jr + 3, vim.api.nvim_buf_line_count(bufnr)), false), "\n"):sub(jc + 1)
      suffix = suffix:match("^%s*;")
      if not suffix then return end
      return {
        row = row, col = start_col,
        prefix = table.concat(vim.api.nvim_buf_get_text(bufnr, sr, sc, ir, ic, {}), "\n"),
        suffix = suffix,
      }
    end
    node = node:parent()
  end
end

function M.attach(client, bufnr)
  if client.name ~= "clangd" or vim.b[bufnr].macro_preview_attached then return end
  if vim.b[bufnr].macro_preview_inspection then return end
  if vim.bo[bufnr].filetype ~= "c" and vim.bo[bufnr].filetype ~= "cpp" then return end
  vim.b[bufnr].macro_preview_attached = true
  shared[client.id] = shared[client.id] or { responses = {}, searches = {}, declarations = {} }
  local caches = shared[client.id]
  local state = { generation = 0, cache = {}, requests = {}, processes = {}, timer = assert(uv.new_timer()) }

  local function close()
    if state.popup and vim.api.nvim_win_is_valid(state.popup) then
      vim.api.nvim_win_close(state.popup, true)
    end
    state.popup = nil
  end

  local function invalidate()
    state.generation = state.generation + 1
    if not state.timer:is_closing() then state.timer:stop() end
    for id in pairs(state.requests) do client:cancel_request(id) end
    state.requests = {}
    for process in pairs(state.processes) do process:kill(15) end
    state.processes = {}
    state.focus = false
    state.key = nil
    close()
  end

  local function location()
    local win = vim.api.nvim_get_current_win()
    if vim.api.nvim_get_current_buf() ~= bufnr or vim.api.nvim_win_get_config(win).relative ~= ""
        or vim.api.nvim_get_mode().mode ~= "n" then return end
    local cursor = vim.api.nvim_win_get_cursor(win)
    local line = vim.api.nvim_get_current_line()
    -- Only trigger while actually on an identifier, not adjacent whitespace.
    local index = cursor[2] + 1
    if not line:sub(index, index):match("[%w_]") then return end
    local first, last = index, index
    while first > 1 and line:sub(first - 1, first - 1):match("[%w_]") do first = first - 1 end
    while line:sub(last + 1, last + 1):match("[%w_]") do last = last + 1 end
    if not line:sub(first, first):match("[%a_]") then return end
    return {
      win = win,
      cursor = cursor,
      name = line:sub(first, last),
      key = table.concat({ vim.api.nvim_buf_get_changedtick(bufnr), cursor[1], first, win }, ":"),
    }
  end

  local function valid(loc, generation)
    if state.generation ~= generation or not vim.api.nvim_buf_is_valid(bufnr) then return false end
    local current = location()
    return current and current.key == loc.key
  end

  local function show(contents)
    if not contents then
      if state.focus then vim.notify("No macro expansion at cursor", vim.log.levels.INFO) end
      state.focus = false
      return
    end
    close()
    local preview, win = vim.lsp.util.open_floating_preview(contents.lines, vim.bo[bufnr].filetype, {
      border = "rounded",
      focus = false,
      focusable = true,
      max_width = math.max(20, math.floor(vim.o.columns * 0.8)),
      max_height = math.max(3, math.floor(vim.o.lines * 0.6)),
      title = " " .. contents.name .. (contents.declaration and " — declaration "
        or contents.enclosing and " — enclosing expansion "
        or contents.arguments and " — expansion + declarations "
        or contents.expanded and " — fully expanded " or " — definition "),
      title_pos = "center",
      footer = " <leader>mx: focus | jj / q / Esc: close ",
      footer_pos = "center",
      close_events = {},
    })
    state.popup = win
    vim.bo[preview].bufhidden = "wipe"
    vim.bo[preview].modifiable = false
    for _, key in ipairs({ "jj", "q", "<Esc>" }) do
      vim.keymap.set("n", key, function()
        state.dismissed = state.key
        invalidate()
      end, { buffer = preview, silent = true, desc = "Close macro preview" })
    end
    if state.focus then vim.api.nvim_set_current_win(win) end
    state.focus = false
  end

  local function request(loc, generation)
    if not valid(loc, generation) or client:is_stopped() then return end
    local cached = cache_get(state.cache, loc.key)
    if cached then
      show(vim.deepcopy(cached.value) or nil)
      return
    end
    local dependencies = { [bufnr] = stamp(bufnr) }
    local function lsp_request(method, request_params, callback, request_buf)
      local key = method .. ":" .. vim.json.encode(request_params)
      local cached_response = cache_get(caches.responses, key)
      if cached_response then
        for buf, version in pairs(cached_response.dependencies) do dependencies[buf] = version end
        vim.schedule(function()
          if valid(loc, generation) then callback(nil, vim.deepcopy(cached_response.value)) end
        end)
        return
      end
      local version, started = stamp(request_buf), revision
      dependencies[request_buf] = version
      local id
      local accepted
      accepted, id = client:request(method, request_params, function(err, result)
        if id then state.requests[id] = nil end
        if not valid(loc, generation) then return end
        if not err and started == revision and stamp(request_buf) == version then
          cache_put(caches.responses, key, result, { [request_buf] = version }, result and 10000 or 2000)
        end
        callback(err, result)
      end, request_buf)
      if accepted then state.requests[id] = true
      else callback({ message = "clangd request unavailable" }, nil) end
    end
    local function process(command, opts, callback)
      local job
      job = vim.system(command, opts, function(result)
        vim.schedule(function()
          state.processes[job] = nil
          if valid(loc, generation) then callback(result) end
        end)
      end)
      state.processes[job] = true
    end
    local params = vim.lsp.util.make_position_params(loc.win, client.offset_encoding)
    local function finish(contents)
      cache_put(state.cache, loc.key, contents or false, dependencies, contents and 10000 or 2000)
      show(contents)
    end
    local function find_enclosing(definition)
      local calls = enclosing_calls(bufnr, loc.cursor)
      local function next_call(index)
        if not valid(loc, generation) or client:is_stopped() then return end
        local call = calls[index]
        if not call then
          if definition then
            local lines = { "// No expansion returned for this token or its enclosing calls." }
            vim.list_extend(lines, definition.lines)
            definition.lines = lines
          end
          finish(definition)
          return
        end
        local outer_params = vim.deepcopy(params)
        local line = vim.api.nvim_buf_get_lines(bufnr, call.row, call.row + 1, false)[1]
        outer_params.position = {
          line = call.row,
          character = vim.str_utfindex(line, client.offset_encoding, call.col, false),
        }
        lsp_request("textDocument/hover", outer_params, function(err, result)
          if not valid(loc, generation) then return end
          local outer = not err and macro_contents(result) or nil
          if outer and outer.expanded then
            outer.enclosing = true
            table.insert(outer.lines, 1, "// Full expansion of enclosing " .. outer.name .. "(...)")
            table.insert(outer.lines, 2, "// Cursor argument: " .. loc.name)
            finish(outer)
          else
            next_call(index + 1)
          end
        end, bufnr)
      end
      next_call(1)
    end
    local find_declaration
    find_declaration = function(fallback, definition_params, symbol_name, done, searched, resolved_target)
      local function handle_definition(err, result)
        if not valid(loc, generation) then return end
        local target = not err and result and (result.uri and result or result[1])
        local uri = target and (target.uri or target.targetUri)
        local range = target and (target.targetSelectionRange or target.range)
        if not uri or not range then fallback(); return end
        local target_buf = inspection_buffer(uri)
        if not target_buf then fallback(); return end
        dependencies[target_buf] = stamp(target_buf)
        local declaration_key = uri .. ":" .. range.start.line .. ":" .. range.start.character
        local saved = cache_get(caches.declarations, declaration_key)
        if saved and (done or saved.value.expanded) then
          for buf, version in pairs(saved.dependencies) do dependencies[buf] = version end
          local callback = done or finish
          callback(vim.deepcopy(saved.value))
          return
        end
        local declaration = generated_declaration(target_buf, range.start, client.offset_encoding)
        local ordinary = not declaration
        if ordinary and not done then fallback(); return end
        -- Ask the same clangd instance that resolved this symbol, including for headers.
        if not vim.lsp.buf_is_attached(target_buf, client.id)
            and not vim.lsp.buf_attach_client(target_buf, client.id) then fallback(); return end
        local target_tick = vim.api.nvim_buf_get_changedtick(target_buf)
        local hover_params = {
          textDocument = { uri = uri },
          position = ordinary and range.start or {
            line = declaration.row,
            character = vim.str_utfindex(vim.api.nvim_buf_get_lines(target_buf,
              declaration.row, declaration.row + 1, false)[1], client.offset_encoding, declaration.col, false),
          },
        }
        lsp_request("textDocument/hover", hover_params, function(hover_err, hover)
          if not valid(loc, generation) then return end
          if not vim.api.nvim_buf_is_valid(target_buf)
              or vim.api.nvim_buf_get_changedtick(target_buf) ~= target_tick then fallback(); return end
          local expansion = not hover_err and macro_contents(hover)
          local text, annotation
          if ordinary then
            if hover_err or not hover or not hover.contents then fallback(); return end
            local hover_lines = vim.lsp.util.convert_input_to_markdown_lines(hover.contents)
            local markup = table.concat(hover_lines, "\n")
            if not markup:match("### variable") and not markup:match("### function") then fallback(); return end
            local code, in_code = {}, false
            for _, line in ipairs(hover_lines) do
              if line:match("^```") then in_code = not in_code
              elseif in_code then code[#code + 1] = line end
            end
            if #code == 0 then fallback(); return end
            text = table.concat(code, "\n")
            if not text:match(";%s*$") then text = text .. ";" end
            annotation = text:match("^extern%s") and " — extern declaration; initializer not resolved by clangd"
              or " — symbol declaration reported by clangd"
            if text:match("^extern%s") and not searched and vim.fn.executable("rg") == 1
                and client.root_dir then
              -- clangd may resolve an extern to the header before indexing its implementation.
              -- Locate initializer candidates, then let clangd interpret the actual declaration.
              local name = symbol_name or loc.name
              local search_key = client.root_dir .. ":" .. name
              local function searched_source(output)
                if not valid(loc, generation) then return end
                local matches = vim.split((output.stdout or ""):gsub("\n$", ""), "\n", { trimempty = true })
                local file, row = (#matches == 1 and matches[1] or ""):match("([^\n]+):(%d+):[^\n]*")
                -- Multiple definitions may represent different build configurations.
                if not file then
                  find_declaration(fallback, definition_params, symbol_name, done, true)
                  return
                end
                local candidate = inspection_buffer(vim.uri_from_fname(file))
                if not candidate then fallback(); return end
                if not vim.lsp.buf_is_attached(candidate, client.id)
                    and not vim.lsp.buf_attach_client(candidate, client.id) then fallback(); return end
                local line = vim.api.nvim_buf_get_lines(candidate, tonumber(row) - 1, tonumber(row), false)[1]
                local col = line and line:find(name, 1, true)
                if not col then fallback(); return end
                local candidate_params = {
                  textDocument = { uri = vim.uri_from_bufnr(candidate) },
                  position = { line = tonumber(row) - 1,
                    character = vim.str_utfindex(line, client.offset_encoding, col - 1, false) },
                }
                find_declaration(fallback, candidate_params, name, done, true, {
                  uri = candidate_params.textDocument.uri,
                  range = { start = candidate_params.position, ["end"] = candidate_params.position },
                })
              end
              local search = cache_get(caches.searches, search_key)
              if search then
                searched_source(search.value)
              else
                process({ "rg", "--line-number", "--no-heading", "--color=never",
                  "--glob", "*.{c,cc,cpp,cxx}", "\\b" .. name .. "\\s*(\\[[^]]*\\])?\\s*=", client.root_dir },
                  { text = true }, function(output)
                    cache_put(caches.searches, search_key, output, {}, 2000)
                    searched_source(output)
                  end)
              end
              return
            end
          else
            if not expansion or not expansion.expanded then fallback(); return end
            text = declaration.prefix .. table.concat(expansion.lines, "\n") .. declaration.suffix
            annotation = " — generated by " .. expansion.name
          end
          local contents = { name = symbol_name or loc.name, declaration = true, expanded = not ordinary }
          local function display(formatted)
            if not valid(loc, generation) then return end
            if not vim.api.nvim_buf_is_valid(target_buf)
                or vim.api.nvim_buf_get_changedtick(target_buf) ~= target_tick then fallback(); return end
            contents.lines = vim.split(formatted:gsub("\n$", ""), "\n", { plain = true })
            table.insert(contents.lines, 1, "// " .. vim.fn.fnamemodify(vim.uri_to_fname(uri), ":~:.")
              .. ":" .. ((declaration and declaration.row or range.start.line) + 1) .. annotation)
            cache_put(caches.declarations, declaration_key, contents, { [target_buf] = stamp(target_buf) })
            local callback = done or finish
            callback(contents)
          end
          local formatter
          for _, cmd in ipairs({ "clang-format", "clang-format-18" }) do
            if vim.fn.executable(cmd) == 1 then formatter = cmd; break end
          end
          if formatter then
            process({ formatter, "--style=file", "--assume-filename=" .. vim.uri_to_fname(uri) }, {
              stdin = text, text = true,
            }, function(output)
              display(output.code == 0 and output.stdout or text)
            end)
          else
            display(text)
          end
        end, target_buf)
      end
      if resolved_target then handle_definition(nil, { resolved_target }); return end
      lsp_request("textDocument/definition", definition_params or params,
        handle_definition, bufnr)
    end
    local function add_argument_declarations(contents)
      local ok, node = pcall(function()
        vim.treesitter.get_parser(bufnr):parse()
        return vim.treesitter.get_node({ bufnr = bufnr, pos = { loc.cursor[1] - 1, loc.cursor[2] } })
      end)
      if not ok then finish(contents); return end
      while node and node:type() ~= "call_expression" do node = node:parent() end
      local arguments = node and node:field("arguments")[1]
      if not arguments then finish(contents); return end
      local symbols, seen = {}, {}
      -- Only direct identifier arguments: do not mistake members, strings or nested calls for symbols.
      for argument in arguments:iter_children() do
        if argument:type() == "identifier" then
          local name = vim.treesitter.get_node_text(argument, bufnr)
          if not seen[name] and #symbols < 8 then
            local row, col = argument:start()
            symbols[#symbols + 1] = { name = name, row = row, col = col }
            seen[name] = true
          end
        end
      end
      local next_index, active, completed, results = 1, 0, 0, {}
      local function pump()
        if not valid(loc, generation) then return end
        if completed == #symbols then
          for index, symbol in ipairs(symbols) do
            if results[index] then
              contents.arguments = true
              contents.lines[#contents.lines + 1] = ""
              contents.lines[#contents.lines + 1] = "// Argument declaration: " .. symbol.name
              vim.list_extend(contents.lines, results[index].lines)
            end
          end
          finish(contents)
          return
        end
        while active < 2 and next_index <= #symbols do
          local index = next_index
          local symbol = symbols[index]
          next_index, active = next_index + 1, active + 1
          local symbol_params = vim.deepcopy(params)
          symbol_params.position = {
            line = symbol.row,
            character = vim.str_utfindex(vim.api.nvim_buf_get_lines(bufnr, symbol.row,
              symbol.row + 1, false)[1], client.offset_encoding, symbol.col, false),
          }
          local function complete(declaration)
            results[index] = declaration
            active, completed = active - 1, completed + 1
            -- Avoid recursive pumping when a lookup is satisfied synchronously from cache.
            vim.schedule(pump)
          end
          find_declaration(function() complete(nil) end, symbol_params, symbol.name, complete)
        end
      end
      pump()
    end
    lsp_request("textDocument/hover", params, function(err, result)
      if not valid(loc, generation) then return end
      if err then
        if state.focus then vim.notify("Macro preview: " .. err.message, vim.log.levels.WARN) end
        state.focus = false
        return
      end
      local contents = macro_contents(result)
      if not contents or not contents.expanded then
        if not contents then
          find_declaration(function() find_enclosing(contents) end)
        else
          find_enclosing(contents)
        end
      else
        add_argument_declarations(contents)
      end
    end, bufnr)
  end

  local function update(manual)
    if manual and state.popup and vim.api.nvim_win_is_valid(state.popup) then
      vim.api.nvim_set_current_win(state.popup)
      return
    end
    local loc = location()
    if not loc then invalidate(); return end
    if not manual and state.dismissed == loc.key then return end
    state.dismissed = nil
    if state.key == loc.key and not manual and state.popup
        and vim.api.nvim_win_is_valid(state.popup) then return end
    invalidate()
    local tick = vim.api.nvim_buf_get_changedtick(bufnr)
    if state.tick ~= tick then state.cache = {}; state.tick = tick end
    state.key = loc.key
    state.source = loc.win
    state.focus = manual
    local generation = state.generation
    if manual then
      request(loc, generation)
    else
      state.timer:start(preview_delay, 0, vim.schedule_wrap(function() request(loc, generation) end))
    end
  end

  vim.keymap.set("n", "<leader>mx", function() update(true) end, {
    buffer = bufnr, silent = true, desc = "Show/focus macro expansion",
  })
  local group = vim.api.nvim_create_augroup("MacroPreview" .. bufnr, { clear = true })
  vim.api.nvim_create_autocmd({ "CursorMoved", "BufEnter", "InsertLeave" }, {
    group = group, buffer = bufnr, callback = function() update(false) end,
  })
  vim.api.nvim_create_autocmd({ "InsertEnter", "TextChanged", "TextChangedI" }, {
    group = group, buffer = bufnr, callback = invalidate,
  })
  vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave" }, {
    group = group, buffer = bufnr, callback = function()
      vim.schedule(function()
        local win = vim.api.nvim_get_current_win()
        if win ~= state.popup and (win ~= state.source or vim.api.nvim_get_current_buf() ~= bufnr) then
          invalidate()
        end
      end)
    end,
  })
  vim.api.nvim_create_autocmd("LspDetach", {
    group = group, buffer = bufnr, callback = function(event)
      if event.data.client_id ~= client.id then return end
      invalidate()
      if not state.timer:is_closing() then state.timer:close() end
      vim.b[bufnr].macro_preview_attached = nil
      vim.keymap.del("n", "<leader>mx", { buffer = bufnr })
      vim.api.nvim_del_augroup_by_id(group)
    end,
  })
  vim.api.nvim_create_autocmd("BufWipeout", {
    group = group, buffer = bufnr, once = true, callback = function()
      invalidate()
      if not state.timer:is_closing() then state.timer:close() end
      vim.api.nvim_del_augroup_by_id(group)
    end,
  })
  update(false)
end

return M
