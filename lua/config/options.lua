
-- Set leader keys
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '


-- Set options for Neovim

-- longer history
vim.opt.history = 500

-- ignore case by default
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.infercase = true

-- indent things. Don't make a # force column zero.
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4

-- Try to show at least three lines and two columns of context when scrolling
-- http://vim.wikia.com/wiki/Make_search_results_appear_in_the_middle_of_the_screen
vim.opt.scrolloff = 3
vim.opt.sidescrolloff = 2

-- Allow edit buffers to be hidden // allows to switch between buffers if the current one is not saved yet
vim.opt.hidden = true

-- enable virtual edit in vblock mode, and one past the end
vim.g.virtualedit=block,onemore

-- Show the cursor line and column
vim.opt.number = true

vim.opt.termguicolors = true

vim.opt.winborder = "rounded"
