local M = {}

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
  table.insert(code, 1, "// Expansion unavailable (empty, oversized, or not an invocation).")
  return { name = name, lines = code, expanded = false }
end

function M.attach(client, bufnr)
  if client.name ~= "clangd" or vim.b[bufnr].macro_preview_attached then return end
  if vim.bo[bufnr].filetype ~= "c" and vim.bo[bufnr].filetype ~= "cpp" then return end
  vim.b[bufnr].macro_preview_attached = true
  local state = { generation = 0, cache = {} }

  local function close()
    if state.popup and vim.api.nvim_win_is_valid(state.popup) then
      vim.api.nvim_win_close(state.popup, true)
    end
    state.popup = nil
  end

  local function invalidate()
    state.generation = state.generation + 1
    if state.request then client:cancel_request(state.request); state.request = nil end
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
      title = " " .. contents.name .. (contents.expanded and " — fully expanded " or " — definition "),
      title_pos = "center",
      footer = " <leader>mx: focus | q / Esc: close ",
      footer_pos = "center",
      close_events = {},
    })
    state.popup = win
    vim.bo[preview].bufhidden = "wipe"
    vim.bo[preview].modifiable = false
    for _, key in ipairs({ "q", "<Esc>" }) do
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
    if state.cache[loc.key] ~= nil then
      show(state.cache[loc.key] or nil)
      return
    end
    local params = vim.lsp.util.make_position_params(loc.win, client.offset_encoding)
    local accepted, id = client:request("textDocument/hover", params, function(err, result)
      if not valid(loc, generation) then return end
      state.request = nil
      if err then
        if state.focus then vim.notify("Macro preview: " .. err.message, vim.log.levels.WARN) end
        state.focus = false
        return
      end
      local contents = macro_contents(result)
      state.cache[loc.key] = contents or false
      show(contents)
    end, bufnr)
    if accepted then state.request = id else state.focus = false end
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
    if state.key == loc.key and not manual then return end
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
      vim.defer_fn(function() request(loc, generation) end, 350)
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
      vim.b[bufnr].macro_preview_attached = nil
      vim.keymap.del("n", "<leader>mx", { buffer = bufnr })
      vim.api.nvim_del_augroup_by_id(group)
    end,
  })
  vim.api.nvim_create_autocmd("BufWipeout", {
    group = group, buffer = bufnr, once = true, callback = function()
      invalidate()
      vim.api.nvim_del_augroup_by_id(group)
    end,
  })
  update(false)
end

return M
