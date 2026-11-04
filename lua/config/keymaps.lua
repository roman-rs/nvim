local silent = { silent = true }

-- general key bindings --

-- jj is esc in insert mode
vim.keymap.set('i', 'jj', '<Esc>', silent)

-- bb is to close current buffer in normal mode
--vim.keymap.set('n', 'bb', ':bd<CR>', silent)

--vim.keymap.set('n', '<leader>sh',  ':LspClangdSwitchSourceHeader<CR>', silent)

-- FzfLua mappings
local fzf_mappings = {
  { "<C-p>", "files", "Find files" },
  { "<C-g>", "grep", "Search project" },
  { "<A-g>", "grep_cword", "Search word under cursor" },
  { "<leader>/", "live_grep", "Live search project" },
  { "<leader>,", "buffers", "Switch buffer" },
  { "<leader>a", "lsp_code_actions", "Code actions" },
  { "<leader>r", "lsp_references", "Find references" },
  { "<leader>d", "lsp_definitions", "Go to definition" },
  { "<leader>D", "lsp_typedefs", "Go to type definition" },
  { "<leader>f", "lsp_finder", "Find LSP locations" },
  { "<leader>gb", "git_blame", "Git blame" },
  { "<leader>ch", "command_history", "Command history" },
  { "<leader>sr", "oldfiles", "Recent files" },
  { "<leader>sR", "resume", "Resume last picker" },
  { "<leader>sb", "blines", "Search current buffer lines" },
  { "<leader>ss", "lsp_document_symbols", "Document symbols" },
  { "<leader>sS", "lsp_live_workspace_symbols", "Workspace symbols" },
  { "<leader>sd", "diagnostics_workspace", "Workspace diagnostics" },
  { "<leader>sD", "diagnostics_document", "Document diagnostics" },
  { "<leader>sq", "quickfix", "Search quickfix list" },
  { "<leader>sk", "keymaps", "Search keymaps" },
  { "<leader>sh", "helptags", "Search help" },
}

for _, mapping in ipairs(fzf_mappings) do
  vim.keymap.set("n", mapping[1], "<cmd>FzfLua " .. mapping[2] .. "<CR>", {
    silent = true,
    desc = mapping[3],
  })
end
vim.keymap.set("x", "<A-g>", "<cmd>FzfLua grep_visual<CR>", {
  silent = true,
  desc = "Search selection",
})

-- Show complete Git status output, including branch and upstream information.
vim.keymap.set("n", "<leader>gs", "<cmd>Git --paginate status<CR>", {
  silent = true,
  desc = "Full Git status",
})

vim.keymap.set('n', '<leader>m',   ':Markview toggle<CR>', silent)
-- quit all
--vim.keymap.set('n', ':q', ':qa<CR>', { noremap = true, silent = true })

-- Ctrl-h / Ctrl-l move between buffers left / right
vim.keymap.set( 'n', '<C-h>', ':bp<CR>', silent)
vim.keymap.set( 'n', '<C-l>', ':bn<CR>', silent)

-- toggle line numbers mapped (to Ctrl+n twice)
vim.keymap.set('n', '<C-N><C-N>', ':set invnumber<CR>', silent)

-- persistence.nvim mappings
-- load the session for the current directory
vim.keymap.set("n", "<leader>qs", function() require("persistence").load() end)
-- select a session to load
vim.keymap.set("n", "<leader>qS", function() require("persistence").select() end)
-- load the last session
vim.keymap.set("n", "<leader>ql", function() require("persistence").load({ last = true }) end)
-- stop Persistence => session won't be saved on exit
vim.keymap.set("n", "<leader>qd", function() require("persistence").stop() end)

vim.keymap.set("n", "K", "<cmd>Lspsaga hover_doc<CR>", { silent = true })


-- git blame
