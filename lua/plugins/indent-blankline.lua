return {
    enabled = true, -- breaks whitespace highlighting
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    ---@module "ibl"
    ---@type ibl.config
    opts = {
        enabled = false,
        whitespace = { highlight = { "Whitespace", "NonText" } },
    },
}
