


require("config.options")
require("config.lazy")


-- General settings --



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

vim.cmd("filetype plugin indent on")



--    nvim-cmp completer
--
vim.diagnostic.config({ virtual_text = true })

-- Setup lspconfig.
local capabilities = require('cmp_nvim_lsp').default_capabilities()
local servers = {
    "clangd",
}

for _, server in ipairs(servers) do
    require('lspconfig')[server].setup({
      capabilities = capabilities,
      on_attach = on_attach
    })
    vim.lsp.enable(server)
end

local lspkind = require('lspkind')
local cmp = require'cmp'

-- Global setup.
cmp.setup({
  snippet = {
    expand = function(args)
      --vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
      require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
      -- require'snippy'.expand_snippet(args.body) -- For `snippy` users.
      -- vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
      --vim.snippet.expand(args.body) -- For native neovim snippets (Neovim v0.10+)

      -- For `mini.snippets` users:
      -- local insert = MiniSnippets.config.expand.insert or MiniSnippets.default_insert
      -- insert({ body = args.body }) -- Insert at cursor
      -- cmp.resubscribe({ "TextChangedI", "TextChangedP" })
      -- require("cmp.config").set_onetime({ sources = {} })
    end,
  },
  window = {
    completion = cmp.config.window.bordered(),
    documentation = cmp.config.window.bordered(),
  },

  mapping = cmp.mapping.preset.insert({
        ['<C-d>'] = cmp.mapping.scroll_docs(-4),
        ['<C-f>'] = cmp.mapping.scroll_docs(4),
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<CR>'] = cmp.mapping.confirm({ select = true }),
        ['<C-j>'] = cmp.mapping.select_next_item(),
        ['<C-k>'] = cmp.mapping.select_prev_item(),
  }),

  formatting = {
    format = lspkind.cmp_format({
      mode = 'symbol_text', -- show only symbol annotations
      maxwidth = {
        -- prevent the popup from showing more than provided characters (e.g 50 will not show more than 50 characters)
        -- can also be a function to dynamically calculate max width such as
        -- menu = function() return math.floor(0.45 * vim.o.columns) end,
        menu = 50, -- leading text (labelDetails)
        abbr = 50, -- actual suggestion item
      },
      ellipsis_char = '...', -- when popup menu exceed maxwidth, the truncated part would show ellipsis_char instead (must define maxwidth first)
      show_labelDetails = true, -- show labelDetails in menu. Disabled by default

      -- The function below will be called before any actual modifications from lspkind
      -- so that you can provide more controls on popup customization. (See [#30](https://github.com/onsails/lspkind-nvim/pull/30))
      before = function (entry, vim_item)
        -- ...
        return vim_item
      end
    })
  },

  view = { docs = { auto_open = false } },

  sources = cmp.config.sources({
    { name = 'buffer', priority=0, max_item_count=30 },
    { name = 'nvim_lsp', priority=1, max_item_count=30 },
    { name = 'nvim_lsp_signature_help' },
    { name = 'luasnip' }, -- For luasnip users.
    -- { name = 'vsnip' }, -- For vsnip users.
    -- { name = 'snippy' }, -- For snippy users.
    -- { name = 'ultisnips' }, -- For ultisnips users.
    -- { name = 'path'},--, max_item_count=10  },
  })
})

-- `/` cmdline setup.
cmp.setup.cmdline('/', {
  mapping = cmp.mapping({
    ['<C-j>'] = cmp.mapping(cmp.mapping.select_next_item(), {'i', 'c'}),
    ['<C-k>'] = cmp.mapping(cmp.mapping.select_prev_item(), {'i', 'c'}),
  }),
  sources = {
    { name = 'buffer', max_item_count=30  }
  }
})

-- `:` cmdline setup.
cmp.setup.cmdline(':', {
  mapping = cmp.mapping({
    ['<C-j>'] = cmp.mapping(cmp.mapping.select_next_item(), {'i', 'c'}),
    ['<C-k>'] = cmp.mapping(cmp.mapping.select_prev_item(), {'i', 'c'}),
  }),
  sources = cmp.config.sources({
    { name = 'path', max_item_count=30},
    { name = 'cmdline', max_item_count=30 }
  }),
  matching = { disallow_symbol_nonprefix_matching = false }
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

local highlight = {
    "RainbowRed",
    "RainbowYellow",
    "RainbowBlue",
    "RainbowOrange",
    "RainbowGreen",
    "RainbowViolet",
    "RainbowCyan",
}
local hooks = require "ibl.hooks"
-- create the highlight groups in the highlight setup hook, so they are reset
-- every time the colorscheme changes
hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
    vim.api.nvim_set_hl(0, "RainbowRed", { fg = "#E06C75" })
    vim.api.nvim_set_hl(0, "RainbowYellow", { fg = "#E5C07B" })
    vim.api.nvim_set_hl(0, "RainbowBlue", { fg = "#61AFEF" })
    vim.api.nvim_set_hl(0, "RainbowOrange", { fg = "#D19A66" })
    vim.api.nvim_set_hl(0, "RainbowGreen", { fg = "#98C379" })
    vim.api.nvim_set_hl(0, "RainbowViolet", { fg = "#C678DD" })
    vim.api.nvim_set_hl(0, "RainbowCyan", { fg = "#56B6C2" })
end)

vim.g.rainbow_delimiters = { highlight = highlight }
require("ibl").setup { scope = { highlight = highlight } }

hooks.register(hooks.type.SCOPE_HIGHLIGHT, hooks.builtin.scope_highlight_from_extmark)
vim.keymap.set('n', '<leader>in', ':IBLToggle<CR>', silent )
vim.cmd([[:IBLDisable]])



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



-- general key bindings --

-- jj is esc in insert mode
vim.keymap.set('i', 'jj', '<Esc>', silent )

-- bb is to close current buffer in normal mode
--vim.keymap.set('n', 'bb', ':bd<CR>', silent )

vim.keymap.set('n', '<leader>sh', ':ClangdSwitchSourceHeader<CR>', silent )
-- quit all
--vim.keymap.set('n', ':q', ':qa<CR>', { noremap = true, silent = true })

-- Ctrl-h / Ctrl-l move between buffers left / right
vim.keymap.set( 'n', '<C-h>', ':bp<CR>', silent )
vim.keymap.set( 'n', '<C-l>', ':bn<CR>', silent )

-- toggle line numbers mapped (to Ctrl+n twice)
vim.keymap.set('n', '<C-N><C-N>', ':set invnumber<CR>', silent )




