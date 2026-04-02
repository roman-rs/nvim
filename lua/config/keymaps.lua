
-- general key bindings --

-- jj is esc in insert mode
vim.keymap.set('i', 'jj', '<Esc>', silent )

-- bb is to close current buffer in normal mode
--vim.keymap.set('n', 'bb', ':bd<CR>', silent )

--vim.keymap.set('n', '<leader>sh',  ':LspClangdSwitchSourceHeader<CR>', silent )

-- FzfLua mappings
vim.keymap.set('n', "<C-p>", ':FzfLua files<CR>', silent )
vim.keymap.set('n', "<C-g>", ':FzfLua grep<CR>', silent )
vim.keymap.set('n', "<A-g>", ':FzfLua grep_cword<CR>', silent )
vim.keymap.set('n', '<leader>a',   ':FzfLua lsp_code_actions<CR>', silent )
vim.keymap.set('n', '<leader>r',   ':FzfLua lsp_references<CR>', silent )
vim.keymap.set('n', '<leader>d',   ':FzfLua lsp_definitions<CR>', silent )
vim.keymap.set('n', '<leader>D',   ':FzfLua lsp_typedefs<CR>', silent )
vim.keymap.set('n', '<leader>f',   ':FzfLua lsp_finder<CR>', silent )
vim.keymap.set('n', '<leader>gs',  ':FzfLua git_status<CR>', silent )
vim.keymap.set('n', '<leader>gb',  ':FzfLua git_blame<CR>', silent )
vim.keymap.set('n', '<leader>h',   ':FzfLua command_history<CR>', silent )
vim.keymap.set('n', '<leader>q',   ':FzfLua diagnostics_document<CR>', silent )
-- quit all
--vim.keymap.set('n', ':q', ':qa<CR>', { noremap = true, silent = true })

-- Ctrl-h / Ctrl-l move between buffers left / right
vim.keymap.set( 'n', '<C-h>', ':bp<CR>', silent )
vim.keymap.set( 'n', '<C-l>', ':bn<CR>', silent )

-- toggle line numbers mapped (to Ctrl+n twice)
vim.keymap.set('n', '<C-N><C-N>', ':set invnumber<CR>', silent )

-- persistence.nvim mappings
-- load the session for the current directory
vim.keymap.set("n", "<leader>qs", function() require("persistence").load() end)
-- select a session to load
vim.keymap.set("n", "<leader>qS", function() require("persistence").select() end)
-- load the last session
vim.keymap.set("n", "<leader>ql", function() require("persistence").load({ last = true }) end)
-- stop Persistence => session won't be saved on exit
vim.keymap.set("n", "<leader>qd", function() require("persistence").stop() end)

-- git blame
