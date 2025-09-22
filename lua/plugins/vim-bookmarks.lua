return {
  "MattesGroeger/vim-bookmarks",
  enabled = true,
  config = function()
    vim.g.bookmark_save_per_working_dir = 1
    vim.g.bookmark_manage_per_buffer = 1
    vim.g.bookmark_highlight_lines = 1
  end,
}
