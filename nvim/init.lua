if vim.fn.has('nvim-0.12') == 0 then
  error('earlgrey.nvim requires Neovim 0.12 or newer; check README.md before installing plugins.')
end

require('plugins')      -- lua/plugins.lua
require('ui')           -- lua/ui.lua
require('plugin_setup') -- lua/plugin_setup.lua
require('snippets')     -- lua/snippets.lua
require('lsp')          -- lua/lsp.lua
require('basic')        -- lua/basic.lua
