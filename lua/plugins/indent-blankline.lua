return {
  enabled = true, -- breaks whitespace highlighting
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
