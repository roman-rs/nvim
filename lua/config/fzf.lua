
local fzf = require'fzf-lua'

-- Global setup.
fzf.setup({
  defaults = {
    file_icons = true,
    git_icons = true,
    color_icons = true,

    -- Customize keybindings for fzf window
    keymap = {
      fzf = {
        ["ctrl-q"] = "select-all+accept",
        ["ctrl-u"] = "half-page-up",
        ["ctrl-d"] = "half-page-down",
      },
    },
  },
  -- Specific commands configuration
  files = {
    -- Use 'fd' for faster file search if installed
    --cmd = "fd --type f --hidden --exclude .git",

    cmd       = "rg --files",
    find_opts = [[-type f \! -path '*/.git/*']],
    rg_opts   = [[--color=never --hidden --files -g "!.git"]],
    fd_opts   = [[--color=never --hidden --type f --type l --exclude .git]],
    dir_opts  = [[/s/b/a:-d]],

    -- Customize preview window
    -- previewer = "bat", -- Use 'bat' for syntax-highlighted preview
    --actions = {
    --  ["default"] = actions.file_edit,
    --  ["ctrl-t"] = actions.file_split,
    --  ["ctrl-v"] = actions.file_vsplit,
    --},
  },
})
