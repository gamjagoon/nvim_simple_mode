local vopt = vim.opt
local vmap = vim.keymap
local silent_opt = {noremap=true, silent = true}

-- View Setting
vopt.mouse  = 'a'
vopt.nu = true
vopt.rnu = true
vopt.ignorecase = true
vopt.cindent = true
vopt.smartcase = false 
vopt.hlsearch = true
vopt.wrap = false
vopt.tabstop = 4
vopt.shiftwidth = 4
vopt.sts = 4
vopt.listchars = {space=' ',tab = '>-', eol = '$'}
vopt.list = true
vim.api.nvim_set_option("clipboard", "unnamed")
vopt.tags = "./tags; tags;"
vim.api.nvim_create_autocmd( 
	{
		"BufEnter",
	},
	{
		pattern = "*.S,*.asm,*.s",
		command = "set syntax=c"
	}
)

vim.api.nvim_create_autocmd( 
	{
		"BufEnter",
	},
	{
		pattern = "*.c,*.h,*.cpp",
		command = "set ts=8 shiftwidth=8 sts=8"
	}
)

-- Key Binding
vmap.set('n', 'cb', '<cmd>bn<bar>bd#<cr><cmd>bp<cr>', silent_opt)

vmap.set('n', '<c-h>','<c-w>h',silent_opt)
vmap.set('n', '<c-j>','<c-w>j',silent_opt)
vmap.set('n', '<c-k>','<c-w>k',silent_opt)
vmap.set('n', '<c-l>','<c-w>l',silent_opt)
vmap.set('n', 'vs','<cmd>vsplit<cr>',silent_opt)

vmap.set('n', '<s-h>','<cmd>bp<cr>',silent_opt)
vmap.set('n', '<s-l>','<cmd>bn<cr>',silent_opt)

vmap.set({'n', 'v'}, '<leader><space>', '<cmd>nohl<cr>', silent_opt)

vmap.set({'n', 'v'}, 'p', '"+p', silent_opt)
vmap.set({'n', 'v'}, 'y', '"+y', silent_opt)
vmap.set({'n', 'v'}, 'P', '"+P', silent_opt)
vmap.set({'n', 'v'}, 'Y', '"+Y', silent_opt)

-- init lua
vmap.set('n', '<leader>it', function()
  vim.cmd.edit(vim.fn.fnameescape(vim.fn.stdpath('config') .. '/init.lua'))
end, silent_opt)

local fzf = require('fzf-lua')
fzf.setup({
  'fzf-vim',
  keymap = {
    builtin = {
      ['<C-k>'] = 'preview-up',
      ['<C-j>'] = 'preview-down',
    },
  },
  actions = {
    files = {
      ['ctrl-o'] = fzf.actions.file_vsplit,
    },
  },
  files = {
    cmd = 'fd --color=never --type f --type l --exclude .git',
  },
  grep = {
    cmd = 'rg --column --line-number --no-heading --color=always --smart-case -e',
    rg_glob = true,
  },
})

-- Search within Neovim's current working directory (:pwd).
vmap.set('n', '<space>ff', function()
  fzf.files({ cwd = vim.fn.getcwd() })
end, silent_opt)
vmap.set('n', '<space>fs', function()
  fzf.grep_cword({ cwd = vim.fn.getcwd() })
end, silent_opt)
vmap.set('n', '<space>fg', function()
  fzf.live_grep({ cwd = vim.fn.getcwd() })
end, silent_opt)
vmap.set('n', '<space>/', function()
  fzf.blines()
end, silent_opt)
vmap.set('n', '<space>rg', function()
  fzf.live_grep({ cwd = vim.fn.getcwd(), search = vim.fn.expand('<cword>') })
end, silent_opt)

-- nvim tree
vim.keymap.set('n', '<space>e', '<cmd>NvimTreeToggle<cr>', {})

-- BUffline
vim.keymap.set('n', '<space>1', '<cmd>BufferLineGoToBuffer 1<cr>', {})
vim.keymap.set('n', '<space>2', '<cmd>BufferLineGoToBuffer 2<cr>', {})
vim.keymap.set('n', '<space>3', '<cmd>BufferLineGoToBuffer 3<cr>', {})
vim.keymap.set('n', '<space>4', '<cmd>BufferLineGoToBuffer 4<cr>', {})
vim.keymap.set('n', '<space>5', '<cmd>BufferLineGoToBuffer 5<cr>', {})
vim.keymap.set('n', '<space>6', '<cmd>BufferLineGoToBuffer 6<cr>', {})
vim.keymap.set('n', '<space>7', '<cmd>BufferLineGoToBuffer 7<cr>', {})
vim.keymap.set('n', '<space>8', '<cmd>BufferLineGoToBuffer 8<cr>', {})
vim.keymap.set('n', '<space>9', '<cmd>BufferLineGoToBuffer 9<cr>', {})

-- highlight
vim.cmd([[set cursorline]])
vim.cmd([[autocmd FileType c,cpp,sh,bash setlocal noet ci pi sts=0 sw=4 ts=4]])
