return {
  enabled = true,
  lazy = true,
  "lukas-reineke/indent-blankline.nvim",
  main = "ibl",
  ---@module "ibl"
  ---@type ibl.config
  opts = {
    enabled = false,
    whitespace = { highlight = { "Whitespace", "NonText" } },
  },
}
