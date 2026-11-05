return {
  { "neovim/nvim-lspconfig" },
  { "hrsh7th/nvim-cmp",
    event = { "InsertEnter", "CmdlineEnter" },
    config = function()
      require("config.nvim-cmp")()
    end,
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
  },
  { "nvimdev/lspsaga.nvim",
    event = "LspAttach",
    cmd = "Lspsaga",
    config = function()
        require('lspsaga').setup({
          lightbulb = { debounce = 250 },
        })
    end,
    dependencies = {
        'nvim-tree/nvim-web-devicons', -- optional
        'nvim-treesitter/nvim-treesitter' -- optional
    },
    enabled = true,
  }
}
