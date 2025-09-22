return {
  "0xfraso/nvim-listchars",
  enabled = true,
  config = function()
    require("nvim-listchars").setup({
      save_state = false,
      listchars = {
        trail = "-",
        eol = "↲",
        tab = "» ",
        space = " ",
      },
      notifications = true,
      exclude_filetypes = {
        "markdown"
      },
      lighten_step = 7,
    })
    --require("nvim-listchars").setup({
    --    enable = true,
    --    listchars = {
    --        --tab = '>',
    --        trail = '-',
    --        nbsp = '+',
    --        eol = '?'
    --    },
    --    notification = true,
    --    lighten_step = 10
    --})
  end,
}
