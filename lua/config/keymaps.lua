
-- general key bindings --

-- jj is esc in insert mode
vim.keymap.set('i', 'jj', '<Esc>', silent )

-- bb is to close current buffer in normal mode
--vim.keymap.set('n', 'bb', ':bd<CR>', silent )

vim.keymap.set('n', '<leader>sh',  ':ClangdSwitchSourceHeader<CR>', silent )

-- FzfLua mappings
vim.keymap.set('n', "<C-p>", ':FzfLua files<CR>', silent )
vim.keymap.set('n', "<C-g>", ':FzfLua grep<CR>', silent )
vim.keymap.set('n', '<leader>lca', ':FzfLua lsp_code_actions<CR>', silent )
vim.keymap.set('n', '<leader>lr',  ':FzfLua lsp_references<CR>', silent )
vim.keymap.set('n', '<leader>lh',  ':FzfLua command_history<CR>', silent )
-- quit all
--vim.keymap.set('n', ':q', ':qa<CR>', { noremap = true, silent = true })

-- Ctrl-h / Ctrl-l move between buffers left / right
vim.keymap.set( 'n', '<C-h>', ':bp<CR>', silent )
vim.keymap.set( 'n', '<C-l>', ':bn<CR>', silent )

-- toggle line numbers mapped (to Ctrl+n twice)
vim.keymap.set('n', '<C-N><C-N>', ':set invnumber<CR>', silent )

