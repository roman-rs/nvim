return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false,
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter").install({
      "markdown",
      "markdown_inline",
      "lua",
      "vim",
      "vimdoc",
      "query",
      "bash",
      "c",
      "cpp",
      "json",
      "yaml",
      "perl",
      "php",
    })

    -- The `main` branch no longer auto-enables highlighting; do it per-buffer.
    vim.api.nvim_create_autocmd("FileType", {
      callback = function(args)
        local buf = args.buf
        local ok, parser = pcall(vim.treesitter.get_parser, buf, nil, { error = false })
        if ok and parser then
          vim.treesitter.start(buf, parser:lang())
        end
      end,
    })
  end,
}
