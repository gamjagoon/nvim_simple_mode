vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
	-- Packer can manage itself
	use "wbthomason/packer.nvim"

	-- UI/colorscheme
	use 'folke/tokyonight.nvim'
	use {
		"nobbmaestro/nvim-andromeda",
		requires = { "tjdevries/colorbuddy.nvim", branch = "dev" }
	}
	use "lukas-reineke/indent-blankline.nvim"
	use {'akinsho/bufferline.nvim', 
			tag = "*", 
			requires = 'nvim-tree/nvim-web-devicons'
	}
	use "b0o/incline.nvim"

	-- lsp
	use "neovim/nvim-lspconfig"
	use "mrcjkb/rustaceanvim"
	use 'rust-lang/rust.vim'
	use "nvim-treesitter/nvim-treesitter"

	-- util
	use "lewis6991/gitsigns.nvim"
	use {
		'nvim-telescope/telescope.nvim',
		requires = {
			{
				"nvim-lua/plenary.nvim",
				"nvim-telescope/telescope-live-grep-args.nvim",
			},
		},
	}
	use {'nvim-telescope/telescope-fzf-native.nvim', run = 'make' }
	use{"nvim-lua/popup.nvim"}
	use {
		"windwp/nvim-autopairs",
	}
	use {
		'nvim-tree/nvim-tree.lua',
		requires = {
			'nvim-tree/nvim-web-devicons', -- optional
		},
		config = function()
			require("nvim-tree").setup {}
		end
	}
	use "RaafatTurki/hex.nvim"
	use {
		"ggandor/leap.nvim",
		require = {
			{
				"tpope/vim-repeat"
			},
		},
	}

	-- auto complete
	use "hrsh7th/cmp-buffer"
	use "hrsh7th/cmp-nvim-lsp"
	use "hrsh7th/cmp-path"
	use "hrsh7th/cmp-cmdline"
	use "hrsh7th/cmp-calc"
	use "hrsh7th/nvim-cmp"
	use "L3MON4D3/LuaSnip"
	use "saadparwaiz1/cmp_luasnip"
	use "joelbeedle/pseudo-syntax"
end)
