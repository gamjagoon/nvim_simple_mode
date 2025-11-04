-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"


return require("lazy").setup({
	-- Packer can manage itself
	"wbthomason/packer.nvim",

	-- UI/colorscheme
	"folke/tokyonight.nvim",
	{
		"everviolet/nvim",
		as = "evergarden"
	},
	"lukas-reineke/indent-blankline.nvim",
	{
		"akinsho/bufferline.nvim", 
		version= "*", 
		dependencies = "nvim-tree/nvim-web-devicons"
	},
	"b0o/incline.nvim",

	-- lsp
	"neovim/nvim-lspconfig",
	{ 
		"mrcjkb/rustaceanvim",
	},
	"rust-lang/rust.vim",
	"nvim-treesitter/nvim-treesitter",

	-- util
	"lewis6991/gitsigns.nvim",
	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			{
				"nvim-lua/plenary.nvim",
				"nvim-telescope/telescope-live-grep-args.nvim",
			},
		},
	},
	{
		"nvim-telescope/telescope-fzf-native.nvim",
		build = "make"
	},
	"nvim-lua/popup.nvim",
	"windwp/nvim-autopairs",
	{
		"nvim-tree/nvim-tree.lua",
		dependencies = {
			"nvim-tree/nvim-web-devicons", -- optional
		},
		config = function()
			require("nvim-tree").setup {}
		end
	},
	{
		"ibhagwan/fzf-lua",
		-- optional for icon support
		dependencies = { "nvim-tree/nvim-web-devicons" },
		-- or if using mini.icons/mini.nvim
		-- dependencies = { "nvim-mini/mini.icons" },
		opts = {}
	},
	"RaafatTurki/hex.nvim",
	"tpope/vim-repeat",
	{
		"ggandor/leap.nvim",
		require = {
			{
				"tpope/vim-repeat"
			},
		},
	},

	-- auto complete
	"hrsh7th/cmp-buffer",
	"hrsh7th/cmp-nvim-lsp",
	"hrsh7th/cmp-path",
	"hrsh7th/cmp-cmdline",
	"hrsh7th/cmp-calc",
	"hrsh7th/nvim-cmp",
	"L3MON4D3/LuaSnip",
	"saadparwaiz1/cmp_luasnip",
	"joelbeedle/pseudo-syntax",
})
