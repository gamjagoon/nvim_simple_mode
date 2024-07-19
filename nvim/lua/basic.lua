local vopt = vim.opt
local vmap = vim.keymap
local silent_opt = {noremap=true, silent = true}

require('leap').create_default_mappings()

-- View Setting
vopt.mouse  = 'a'
vopt.nu = true
vopt.rnu = true
vopt.ignorecase = true
vopt.smartcase  = true
vopt.hlsearch = true
vim.cmd([[set smartindent]])
vopt.wrap = false
vopt.tabstop = 4
vopt.shiftwidth = 4
vopt.listchars = {space='·',tab = '> ', eol = '$'}
vopt.list = true
vopt.clipboard = "unnamedplus"
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


-- Key Binding
vmap.set('n', 'cb', '<cmd>bn<bar>bd#<cr><cmd>bp<cr>', silent_opt)

vmap.set('n', '<c-h>','<c-w>h',silent_opt)
vmap.set('n', '<c-j>','<c-w>j',silent_opt)
vmap.set('n', '<c-k>','<c-w>k',silent_opt)
vmap.set('n', '<c-l>','<c-w>l',silent_opt)
vmap.set('n', 'sp','<cmd>split<cr>',silent_opt)
vmap.set('n', 'vs','<cmd>vsplit<cr>',silent_opt)

vmap.set('n', '<s-h>','<cmd>bp<cr>',silent_opt)
vmap.set('n', '<s-l>','<cmd>bn<cr>',silent_opt)

vmap.set({'n', 'v'}, '<leader><space>', '<cmd>nohl<cr>', silent_opt)

vmap.set({'n', 'v'}, 'p', '"+p', silent_opt)
vmap.set({'n', 'v'}, 'y', '"+y', silent_opt)
vmap.set({'n', 'v'}, 'P', '"+P', silent_opt)
vmap.set({'n', 'v'}, 'Y', '"+Y', silent_opt)

-- init lua
vmap.set('n', '<leader>it','<cmd>e ~/.config/nvim/init.lua<cr>',silent_opt)

-- telescope 
vim.keymap.set('n', '<space>ff', "<cmd>Telescope find_files<cr>", {})
vim.keymap.set('n', '<space>fs', "<cmd>Telescope grep_string<cr>", {})
vim.keymap.set('n', '<space>fg', "<cmd>Telescope live_grep_args theme=ivy <cr>", {})
vim.keymap.set('n', '<space>/', "<cmd> Telescope current_buffer_fuzzy_find theme=ivy<cr>", {})

local function search_word_under_cursor()
  local word = vim.fn.expand("<cword>")
  require('telescope').extensions.live_grep_args.live_grep_args({ default_text = word})
end

vim.keymap.set("n", "<space>rg", search_word_under_cursor, silent_opt)

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
vim.cmd([[set cursorline]])
vim.cmd([[autocmd FileType c,cpp,sh,bash setlocal noet ci pi sts=0 sw=4 ts=4]])

-- Rust Setup
local bufnr = vim.api.nvim_get_current_buf()
vim.keymap.set(
	"n", 
	"<space>ca", 
	function()
		vim.cmd.RustLsp('codeAction') -- supports rust-analyzer's grouping or vim.lsp.buf.codeAction() if you don't want grouping.
	end,
	{ silent = true, buffer = bufnr }
)

vim.keymap.set( "n", "<space>rl",':RustLsp ' ,{})

vim.keymap.set(
	"n", 
	"<space>dr", 
	function()
		vim.cmd.RustLsp('renderDiagnotic') -- supports rust-analyzer's grouping or vim.lsp.buf.codeAction() if you don't want grouping.
	end,
	{ silent = true }
)

vim.keymap.set(
	"n",
	"<space>de",
	function()
		vim.cmd.RustLsp('explainError') -- supports rust-analyzer's grouping or vim.lsp.buf.codeAction() if you don't want grouping.
	end,
	{ silent = true }
)
