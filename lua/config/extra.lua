
-- General settings --

vim.cmd("filetype plugin indent on")
vim.diagnostic.config({ virtual_text = true })

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


-- Highlight trailing whitespace --
vim.api.nvim_set_hl(0, "ExtraWhitespace", {
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

