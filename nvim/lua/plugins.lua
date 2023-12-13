vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
	-- Packer can manage itself
	use "wbthomason/packer.nvim"
	-- colorscheme
	use 'folke/tokyonight.nvim'
	use "neovim/nvim-lspconfig"
	use "simrat39/rust-tools.nvim"
	use "lukas-reineke/indent-blankline.nvim"
	use "nvim-treesitter/nvim-treesitter"
	use "lewis6991/gitsigns.nvim"
	use "L3MON4D3/LuaSnip"
	use "saadparwaiz1/cmp_luasnip"
	use {'akinsho/bufferline.nvim', 
			tag = "*", 
			requires = 'nvim-tree/nvim-web-devicons'
	}
	use "RaafatTurki/hex.nvim"
	use {
		'nvim-telescope/telescope.nvim',
		requires = {
			{
				"nvim-lua/plenary.nvim",
				"nvim-telescope/telescope-live-grep-args.nvim",
			},
		},
	}
	use { 'nvim-telescope/telescope-fzf-native.nvim', run = 'make' }
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
	-- auto complete
	use "hrsh7th/cmp-buffer"
	use "hrsh7th/cmp-nvim-lsp"
	use "hrsh7th/cmp-path"
	use "hrsh7th/cmp-cmdline"
	use "hrsh7th/cmp-calc"
	use "hrsh7th/nvim-cmp"
end)
