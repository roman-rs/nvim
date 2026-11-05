local M = {}

function M.open()
  local cwd = vim.fn.getcwd()
  local winopts = require("fzf-lua.config").globals.winopts
  local width = math.max(1, math.min(vim.o.columns - 2, math.floor(vim.o.columns * winopts.width)))
  local available_height = vim.o.lines - vim.o.cmdheight - 2
  local height = math.max(1, math.floor(available_height * winopts.height))
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "git"
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.max(0, math.floor((available_height - height) * winopts.row)),
    col = math.max(0, math.floor((vim.o.columns - width - 2) * winopts.col)),
    border = winopts.border,
    title = " Git status ",
    title_pos = "center",
    footer = " r: refresh | jj / q / Esc: close ",
    footer_pos = "center",
    style = "minimal",
  })
  vim.wo[win].wrap = false

  local function set_lines(lines)
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
  end

  local generation = 0
  local function refresh()
    generation = generation + 1
    local request = generation
    set_lines({ "Loading Git status..." })
    vim.system({ "git", "-c", "color.status=false", "--no-optional-locks", "status" }, {
      cwd = cwd,
      text = true,
    }, function(result)
      vim.schedule(function()
        if request ~= generation or not vim.api.nvim_buf_is_valid(buf)
            or not vim.api.nvim_win_is_valid(win) then
          return
        end
        local output = result.code == 0 and result.stdout or result.stderr
        if not output or output == "" then
          output = "Git status failed (exit " .. result.code .. ")"
        end
        set_lines(vim.split(output:gsub("\n$", ""), "\n", { plain = true }))
        vim.api.nvim_win_set_cursor(win, { 1, 0 })
      end)
    end)
  end

  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end
  for _, key in ipairs({ "jj", "q", "<Esc>" }) do
    vim.keymap.set("n", key, close, { buffer = buf, silent = true, desc = "Close Git status" })
  end
  vim.keymap.set("n", "r", refresh, { buffer = buf, silent = true, desc = "Refresh Git status" })
  refresh()
end

return M
