
return {
  {
    "ibhagwan/fzf-lua",
    enabled = true,
    lazy = true,
    -- optional for icon support
    dependencies = { "nvim-tree/nvim-web-devicons" },
    -- or if using mini.icons/mini.nvim
    -- dependencies = { "echasnovski/mini.icons" },
    opts = {},
    keys = {
        --{ "<C-d>", "preview-page-down", desc = "Fzf page down", mode = "n" },
        --{ "<C-p>", "[[:FzfLua files<CR>", desc = "Fzf files", mode = "n" },
        { "<C-p>", "[[:FzfLua files<CR>", desc = "Fzf files", mode = "n" },
        { "<C-g>", "[[:FzfLua grep<CR>", desc = "Fzf files", mode = "n" },
    }
  }
}
