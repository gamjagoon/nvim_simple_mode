local telescope = require("telescope")
local lga_actions = require("telescope-live-grep-args.actions")
local cmp = require('cmp')
local autopair = require('nvim-autopairs')

require'nvim-treesitter.configs'.setup {
	sync_install = false,
	auto_install = false,
	ignore_install = { "javascript" },
	highlight = {
	enable = true,
	-- disable = { "c", "rust" },
	disable = function(lang, buf)
	local max_filesize = 200 * 1024 -- 100 KB
	local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
	if ok and stats and stats.size > max_filesize then
		return true
	end
	end,
	additional_vim_regex_highlighting = true,
	},
}

telescope.setup {
	defaults = {
		mappings = {
			i = {
				["<C-h>"] = "which_key",
				["<C-k>"] = lga_actions.quote_prompt(),
			},
		},
	},
	pickers = {
	},
	extensions = {
		live_grep_args = {
			auto_quoting = true, -- enable/disable auto-quoting
			mappings = { -- extend mappings
				i = {
						["<C-k>"] = lga_actions.quote_prompt(),
						["<C-i>"] = lga_actions.quote_prompt({ postfix = " --iglob " }),
					},
			},
		},
		fzf = {
			fuzzy = true,					-- false will only do exact matching
			override_generic_sorter = true,  -- override the generic sorter
			override_file_sorter = true,	 -- override the file sorter
			case_mode = "respect_case",		-- or "ignore_case" or "respect_case"
									   --	   the default case_mode is "smart_case"
		},
	}
}

require('nvim-treesitter.parsers').get_parser_configs().asm = {
	install_info = {
		url = 'https://github.com/rush-rs/tree-sitter-asm.git',
		files = { 'src/parser.c' },
		branch = 'main',
	},
}

require('telescope').load_extension('fzf')

cmp.setup({
	snippet = {
		expand = function(args)
			require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
		end,
	},
	sources = cmp.config.sources({
		{name = 'nvim_lsp'},
		{name = 'path'},
		{name = 'buffer'},
		{name = 'luasnip'},
	}),
	mapping = cmp.mapping.preset.insert({
	  ['<C-b>'] = cmp.mapping.scroll_docs(-4),
	  ['<C-f>'] = cmp.mapping.scroll_docs(4),
	  ['<C-Space>'] = cmp.mapping.complete(),
	  ['<C-e>'] = cmp.mapping.abort(),
	  ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
	}),
})

-- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline({ '/', '?' }, {
  mapping = cmp.mapping.preset.cmdline(),
  sources = {
	{name = 'buffer',
	  option = {
		get_bufnrs = function()
		  local bufs = {}
		  for _, win in ipairs(vim.api.nvim_list_wins()) do
			bufs[vim.api.nvim_win_get_buf(win)] = true
		  end
		  return vim.tbl_keys(bufs)
		end
	  }
	},
  }
})

-- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline(':', {
  mapping = cmp.mapping.preset.cmdline(),
  sources = cmp.config.sources({
	{ name = 'path' }
  }, {
	{ name = 'cmdline' }
  })
})


autopair.setup({
	disable_filetype = { "TelescopePrompt", "vim" },
})


require('gitsigns').setup {
	signs = {
			add		  = { text = '│' },
			change	   = { text = '│' },
			delete	   = { text = '_' },
			topdelete	= { text = '‾' },
			changedelete = { text = '~' },
			untracked	= { text = '┆' },
	},
	signcolumn = true,  -- Toggle with `:Gitsigns toggle_signs`
	numhl	  = true, -- Toggle with `:Gitsigns toggle_numhl`
	linehl	 = false, -- Toggle with `:Gitsigns toggle_linehl`
	word_diff  = false, -- Toggle with `:Gitsigns toggle_word_diff`
	watch_gitdir = {
		follow_files = true
	},
	attach_to_untracked = true,
	current_line_blame = true, -- Toggle with `:Gitsigns toggle_current_line_blame`
	current_line_blame_opts = {
		virt_text = true,
		virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
		delay = 100,
		ignore_whitespace = false,
		virt_text_priority = 100,
	},
	current_line_blame_formatter = '<author>, <author_time:%Y-%m-%d> - <summary>',
	sign_priority = 6,
	update_debounce = 50,
	status_formatter = nil, -- Use default
	max_file_length = 40000, -- Disable if file is longer than this (in lines)
	preview_config = {
	-- Options passed to nvim_open_win
	border = 'single',
	style = 'minimal',
	relative = 'cursor',
	row = 0,
	col = 1
	},
	yadm = {
	enable = false
	},
	on_attach = function(bufnr)
	local function map(mode, lhs, rhs, opts)
		opts = vim.tbl_extend('force', {noremap = true, silent = true}, opts or {})
		vim.api.nvim_buf_set_keymap(bufnr, mode, lhs, rhs, opts)
	end

	-- Navigation
	map('n', ']c', "&diff ? ']c' : '<cmd>Gitsigns next_hunk<CR>'", {expr=true})
	map('n', '[c', "&diff ? '[c' : '<cmd>Gitsigns prev_hunk<CR>'", {expr=true})

	-- Actions
	map('n', '<space>hs', ':Gitsigns stage_hunk<CR>')
	map('v', '<space>hs', ':Gitsigns stage_hunk<CR>')
	map('n', '<space>hr', ':Gitsigns reset_hunk<CR>')
	map('v', '<space>hr', ':Gitsigns reset_hunk<CR>')
	map('n', '<space>hS', '<cmd>Gitsigns stage_buffer<CR>')
	map('n', '<space>hu', '<cmd>Gitsigns undo_stage_hunk<CR>')
	map('n', '<space>hR', '<cmd>Gitsigns reset_buffer<CR>')
	map('n', '<space>hp', '<cmd>Gitsigns preview_hunk<CR>')
	map('n', '<space>hb', '<cmd>lua require"gitsigns".blame_line{full=true}<CR>')
	map('n', '<space>tb', '<cmd>Gitsigns toggle_current_line_blame<CR>')
	map('n', '<space>hd', '<cmd>Gitsigns diffthis<CR>')
	map('n', '<space>hD', '<cmd>lua require"gitsigns".diffthis("~")<CR>')
	map('n', '<space>td', '<cmd>Gitsigns toggle_deleted<CR>')

	-- Text object
	map('o', 'ih', ':<C-U>Gitsigns select_hunk<CR>')
	map('x', 'ih', ':<C-U>Gitsigns select_hunk<CR>')
  end
}

require 'hex'.setup()
