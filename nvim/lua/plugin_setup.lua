local autopair = require('nvim-autopairs')

local treesitter = require('nvim-treesitter')
treesitter.setup({})
treesitter.install({ 'markdown', 'markdown_inline' })

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('UserTreesitter', { clear = true }),
  callback = function(ev)
    local lang = vim.treesitter.language.get_lang(vim.bo[ev.buf].filetype)
    if not lang then
      return
    end
    if not vim.treesitter.language.add(lang) then
      return
    end
    local stats = (vim.uv or vim.loop).fs_stat(vim.api.nvim_buf_get_name(ev.buf))
    if stats and stats.size > 200 * 1024 then
      return
    end
    vim.treesitter.start(ev.buf, lang)
  end,
})

autopair.setup({
	disable_filetype = { "vim" },
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
