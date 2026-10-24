-- Also prepare future interactive parser builds, beyond the installer process.
require('compat').setup_windows_toolchain()

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
	{
		"rcarriga/nvim-notify",
		lazy = false,
		priority = 900,
		config = function()
			local notify = require("notify")
			notify.setup({ stages = "static", timeout = 5000, render = "wrapped-compact",
				max_width = 60, background_colour = "#1a1b26" })
			vim.notify = notify
			require("agent_notifications").setup()
		end,
	},
	-- UI/colorscheme
	"folke/tokyonight.nvim",
	{
		"everviolet/nvim",
		name = "evergarden"
	},
	{
		"shellRaining/hlchunk.nvim",
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			chunk = { enable = true },
			indent = { enable = true },
		},
	},
	{
		"akinsho/bufferline.nvim", 
		version= "*", 
		dependencies = "nvim-tree/nvim-web-devicons"
	},
	"b0o/incline.nvim",
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
	},

	-- lsp
	"neovim/nvim-lspconfig",
	{ 
		"mrcjkb/rustaceanvim",
		lazy = false,
		init = function()
			vim.g.rustaceanvim = {
				tools = {
					hover_actions = { replace_builtin_hover = true },
					float_win_config = { border = "none", auto_focus = true },
				},
				server = {
					on_attach = function(_, bufnr)
						vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
					end,
				},
			}
		end,
	},
	{
		"rust-lang/rust.vim",
		init = function()
			vim.g.rustfmt_autosave = 1
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		lazy = false,
		build = ":TSUpdate",
	},
	{
		"MeanderingProgrammer/render-markdown.nvim",
		ft = { "markdown" },
		cmd = { "RenderMarkdown" },
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-tree/nvim-web-devicons",
		},
		opts = { completions = { lsp = { enabled = true } } },
	},

	-- util
	"lewis6991/gitsigns.nvim",
	"windwp/nvim-autopairs",
	{
		"nvim-tree/nvim-tree.lua",
		dependencies = {
			"nvim-tree/nvim-web-devicons", -- optional
		},
	},
	{
		"ibhagwan/fzf-lua",
		-- optional for icon support
		dependencies = { "nvim-tree/nvim-web-devicons" },
	},
	"RaafatTurki/hex.nvim",
	"tpope/vim-repeat",

	-- auto complete
	{
		"saghen/blink.cmp",
		version = "1.*",
		dependencies = { "L3MON4D3/LuaSnip" },
		opts = {
			keymap = {
				preset = "enter",
				["<C-k>"] = false, -- Keep LuaSnip's explicit expansion shortcut.
				["<C-e>"] = {
					"cancel",
					function()
						local ls = require("luasnip")
						if ls.choice_active() then
							ls.change_choice(1)
							return true
						end
					end,
					"fallback",
				},
			},
			snippets = { preset = "luasnip" },
			sources = { default = { "lsp", "path", "snippets", "buffer" } },
			completion = {
				list = { selection = { preselect = true, auto_insert = false } },
				documentation = { auto_show = true },
			},
			cmdline = {
				keymap = { preset = "cmdline" },
				completion = { menu = { auto_show = true } },
			},
		},
	},
	"joelbeedle/pseudo-syntax",
}, {
	-- These plugins use Git checkouts; none require LuaRocks packages.
	rocks = { enabled = false },
})
