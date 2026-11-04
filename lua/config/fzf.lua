local fzf = require("fzf-lua")

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
        ["ctrl-w"] = "toggle-preview-wrap",
        ["ctrl-p"] = "toggle-preview",
        ["alt-j"] = "preview-page-down",
        ["alt-k"] = "preview-page-up",
      },
      builtin = {
        ["<c-w>"] = "toggle-preview-wrap",
        ["<c-p>"] = "toggle-preview",
        ["<a-f>"] = "toggle-fullscreen",
        ["<a-j>"] = "preview-page-down",
        ["<a-k>"] = "preview-page-up",
      },
    },
  },
  fzf_colors = true,

  lsp = {
    code_actions = {
      previewer = vim.fn.executable("delta") == 1 and "codeaction_native" or "codeaction",
    },
  },

  winopts = {
    border = "rounded",
    preview = {
      vertical = "down:45%",
      horizontal = "right:60%",
      layout = "flex",
      flip_columns = 120,
    },
  },

  files = {
    -- Use auto-detected fd/fdfind, rg, or find with upstream command options.
    hidden = true,
    follow = false,
    no_ignore = false,
    formatter = "path.filename_first",
  },

  grep = {
    hidden = true,
    follow = false,
    no_ignore = false,
    -- Keep Git internals out of searches even when ignored files are enabled.
    rg_opts = [[--column --line-number --no-heading --color=always --smart-case --max-columns=4096 --glob '!.git' -e]],
  },

  oldfiles = {
    cwd_only = true,
    include_current_session = true,
  },

  buffers = {
    show_unloaded = true,
  },
})

fzf.register_ui_select()
