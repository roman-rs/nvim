return {
  {"simrat39/rust-tools.nvim"},
  { "neovim/nvim-lspconfig" },
  -- { "RishabhRD/nvim-lsputils",
  --   keys = {
  --       --{ "<C-d>", "preview-page-down", desc = "Fzf page down", mode = "n" },
  --       --{ "<C-p>", "[[:FzfLua files<CR>", desc = "Fzf files", mode = "n" },
  --       { "<leader>a", vim.lsp.buf.code_action, desc = "Fzf files", mode = "n" },
  --   }
  -- },
  { "hrsh7th/nvim-cmp",
    dependencies = {
      { "hrsh7th/cmp-nvim-lsp" },
      { "hrsh7th/cmp-buffer" },
      { "hrsh7th/cmp-path" },
      { "hrsh7th/cmp-cmdline" },
      { "hrsh7th/cmp-nvim-lsp-signature-help" },
      { "onsails/lspkind.nvim" },
      {
        "L3MON4D3/LuaSnip",
        -- follow latest release.
        version = "v2.*", -- Replace <CurrentMajor> by the latest released major (first number of latest release)
        -- install jsregexp (optional!).
        build = "make install_jsregexp"
      }
    },
    enabled = true,
  }
}
