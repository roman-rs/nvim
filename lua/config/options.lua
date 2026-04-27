
-- Set leader keys
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '


-- Set options for Neovim

-- longer history
vim.opt.history = 500

-- line width
vim.opt.colorcolumn = "80"

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
vim.opt.virtualedit = "block,onemore"

-- Show the cursor line and column
vim.opt.number = true

vim.opt.termguicolors = true

vim.opt.winborder = "rounded"

-- OSC 52 clipboard: works over SSH, with or without tmux
-- (tmux needs: set -g set-clipboard on; set -g allow-passthrough on)
vim.g.clipboard = {
  name = "OSC 52",
  copy = {
    ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
    ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
  },
  paste = {
    ["+"] = function()
      -- Paste from the unnamed register (local buffer) since OSC 52
      -- does not support reading the clipboard back over SSH
      return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") }
    end,
    ["*"] = function()
      return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") }
    end,
  },
}
vim.opt.clipboard = "unnamedplus"
