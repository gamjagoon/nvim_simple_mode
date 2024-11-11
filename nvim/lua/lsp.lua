local lsp_capabilites = require("cmp_nvim_lsp").default_capabilities()
local lspconfig = require('lspconfig')

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspConfig', {}),
  callback = function(ev)
    -- Enable completion triggered by <c-x><c-o>
    vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'
    local opts = { buffer = ev.buf, noremap=true, silent = true }
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
    vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, opts)
    vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, opts)
    vim.keymap.set({ 'n', 'v' }, '<space>ca', vim.lsp.buf.code_action, opts)
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
  end,
})

lspconfig.pylsp.setup{}

--lspconfig.clangd.setup{}

--lspconfig.lua_ls.setup {
--  on_init = function(client)
--    local path = client.workspace_folders[1].name
--    if vim.loop.fs_stat(path..'/.luarc.json') or vim.loop.fs_stat(path..'/.luarc.jsonc') then
--      return
--    end
--
--    client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
--      runtime = {
--        version = 'LuaJIT'
--      },
--      -- Make the server aware of Neovim runtime files
--      workspace = {
--        checkThirdParty = false,
--        library = {
--          vim.env.VIMRUNTIME
--          -- Depending on the usage, you might want to add additional paths here.
--          -- "${3rd}/luv/library"
--          -- "${3rd}/busted/library",
--        }
--        -- or pull in all of 'runtimepath'. NOTE: this is a lot slower
--        -- library = vim.api.nvim_get_runtime_file("", true)
--      }
--    })
--  end,
--  settings = {
--    Lua = {}
--  }
--}

vim.g.rustaceanvim = {
  -- Plugin configuration
  tools = {
		hover_actions = {
			replace_builtin_hover = true,
		},
		float_win_config = {
			border = "none",
			auto_focus = true,
		},
  },
  -- LSP configuration
  server = {
    on_attach = function(client, bufnr)
	  vim.lsp.inlay_hint.enable(true)
    end,
    default_settings = {
      -- rust-analyzer language server configuration
      ['rust-analyzer'] = {
      },
    },
  },
  -- DAP configuration
  dap = {
  },
}

vim.g.rustfmt_autosave = 1

-- LSP Diagnostics Options Setup 
local sign = function(opts)
vim.fn.sign_define(opts.name, {
    texthl = opts.name,
    text = opts.text,
    numhl = ''
  })
end

sign({name = 'DiagnosticSignError', text = 'E'})
sign({name = 'DiagnosticSignWarn', text = ''})
sign({name = 'DiagnosticSignHint', text = 'H'})
sign({name = 'DiagnosticSignInfo', text = ''})

vim.diagnostic.config({
    virtual_text = true,
    signs = true,
    update_in_insert = true,
    underline = true,
    severity_sort = false,
    float = {
        border = 'rounded',
        source = 'always',
        header = '',
        prefix = '',
    },
})

vim.cmd([[
set signcolumn=yes
autocmd CursorHold * lua vim.diagnostic.open_float(nil, { focusable = false })
]])
