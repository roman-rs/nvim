
require("config.options")

require("config.lazy")

require("config.nvim-cmp")
require("config.indent-blankline")

require("config.keymaps")


-- General settings --
vim.diagnostic.config({ virtual_text = true })
vim.cmd("filetype plugin indent on")

-- jump to last position in file
vim.api.nvim_create_autocmd("BufReadPost", {
  pattern = { "*" }, -- Apply to all files
  desc = "remember last cursor place",
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})




--test -- indent setup
--test local highlight = {
--test     "RainbowRed",
--test     "RainbowYellow",
--test     "RainbowBlue",
--test     "RainbowOrange",
--test     "RainbowGreen",
--test     "RainbowViolet",
--test     "RainbowCyan",
--test }
--test 
--test local hooks = require "ibl.hooks"
--test -- create the highlight groups in the highlight setup hook, so they are reset
--test -- every time the colorscheme changes
--test hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
--test     vim.api.nvim_set_hl(0, "RainbowRed", { fg = "#E06C75" })
--test     vim.api.nvim_set_hl(0, "RainbowYellow", { fg = "#E5C07B" })
--test     vim.api.nvim_set_hl(0, "RainbowBlue", { fg = "#61AFEF" })
--test     vim.api.nvim_set_hl(0, "RainbowOrange", { fg = "#D19A66" })
--test     vim.api.nvim_set_hl(0, "RainbowGreen", { fg = "#98C379" })
--test     vim.api.nvim_set_hl(0, "RainbowViolet", { fg = "#C678DD" })
--test     vim.api.nvim_set_hl(0, "RainbowCyan", { fg = "#56B6C2" })
--test end)
--test 
--test require("ibl").setup { indent = { highlight = highlight } }



-- Highlight trailing whitespace --
vim.api.nvim_set_hl(0, "ExtraWhitespace",
{
    ctermbg = "red",
    bg = "red"
})

extra_ws = true;
hi_ws_match0 = vim.fn.matchadd("ExtraWhitespace", [[\s\+$]])
hi_ws_match1 = vim.fn.matchadd("ExtraWhitespace", [[^\s\+$]])

function toggleHI()
    if extra_ws == false then
        hi_ws_match0 = vim.fn.matchadd("ExtraWhitespace", [[\s\+$]])
        hi_ws_match1 = vim.fn.matchadd("ExtraWhitespace", [[^\s\+$]])
        extra_ws = true;
    else
        --vim.fn.matchdelete(vim.fn.matcharg(0, "ExtraWhitespace"))
        vim.fn.matchdelete(hi_ws_match0)
        vim.fn.matchdelete(hi_ws_match1)
        extra_ws = false;
    end
end
vim.keymap.set( 'n', '<leader>ws', toggleHI, silent )



