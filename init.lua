
require("config.options")

require("config.lazy")

require("config.nvim-cmp")
require("config.indent-blankline")

require("config.keymaps")

require("config.extra")

-- transparency
vim.api.nvim_set_hl(0, "Normal", { bg = "NONE", ctermbg = "NONE" })
vim.api.nvim_set_hl(0, "NormalFloat", { bg = "NONE", ctermbg = "NONE" })
