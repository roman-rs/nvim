return {
  "ibhagwan/fzf-lua",
  enabled = true,
  cmd = "FzfLua",
  config = function()
    require("config.fzf")
  end,
  init = function()
    vim.ui.select = function(...)
      require("fzf-lua")
      return vim.ui.select(...)
    end
  end,
  -- Icon support; setup and mappings live in lua/config/fzf.lua and keymaps.lua.
  dependencies = { "nvim-tree/nvim-web-devicons" },
}
