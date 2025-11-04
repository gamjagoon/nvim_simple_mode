--vim.opt.background="dark"
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.opt.termguicolors = true

-- ==============================================
-- SET COLORSCHEME
-- ==============================================

require("tokyonight").setup({
  style = "storm", -- The theme comes in three styles, `storm`, `moon`, a darker variant `night` and `day`
  light_style = "day", -- The theme is used when the background is set to light
  transparent = true, -- Enable this to disable setting the background color
  terminal_colors = true, -- Configure the colors used when opening a `:terminal` in [Neovim](https://github.com/neovim/neovim)
  styles = {
    comments = { italic = true },
    keywords = { italic = true },
    functions = {bold = true},
    variables = {bold = true},
    sidebars = "dark", -- style for sidebars, see below
    floats = "dark", -- style for floating windows
  },
  sidebars = { "qf", "help" }, -- Set a darker background on sidebar-like windows. For example: `["qf", "vista_kind", "terminal", "packer"]`
  day_brightness = 0.5, -- Adjusts the brightness of the colors of the **Day** style. Number between 0 and 1, from dull to vibrant colors
  hide_inactive_statusline = true, -- Enabling this option, will hide inactive statuslines and replace them with a thin border instead. Should work with the standard **StatusLine** and **LuaLine**.
  dim_inactive = false, -- dims inactive windows
  on_highlights = function (hl, c)
      hl.StatusLine = {
          bg = "#81abfd",
          fg = "#3b4261"
      }
      hl.StatusLineNC = {
          bg = "#455981",
          fg = "#e5eeff"
      }
      hl.CursorLineNr = {
          fg = "#cc0000"
      }
      hl.LineNr= {
          fg = "#ff743d"
      }
  end
})
--require("tokyonight").load()

require("evergarden").setup {
  theme = {
    variant = 'winter', -- 'winter'|'fall'|'spring'|'summer'
    accent = 'green',
  },
  editor = {
    transparent_background = false,
    override_terminal = true,
    sign = { color = 'none' },
    float = {
      color = 'mantle',
      invert_border = false,
    },
    completion = {
      color = 'surface0',
    },
  },
  style = {
    tabline = { 'reverse' },
    search = { 'italic', 'reverse' },
    incsearch = { 'italic', 'reverse' },
    types = { 'italic' },
    keyword = { 'italic' },
    comment = { 'italic' },
  },
  overrides = {},
  color_overrides = {},
  integrations = {
    --blink_cmp = true,
    cmp = true,
    --fzf_lua = true,
    gitsigns = true,
    indent_blankline = { enable = true, scope_color = 'red' },
    nvimtree = true,
    --rainbow_delimiters = true,
    --symbols_outline = true,
    telescope = true,
    --which_key = true,
    --neotree = true,
  },
}
require("evergarden").load()


-- ==============================================
-- SET OTHER UI
-- ==============================================

require('bufferline').setup {
    options = {
        numbers = "ordinal",
        buffer_close_icon = '󰅖',
        modified_icon = '●',
        close_icon = '',
        left_trunc_marker = '',
        right_trunc_marker = '',
        max_name_length = 18,
        max_prefix_length = 15, -- prefix used when a buffer is de-duplicated
        truncate_names = true, -- whether or not tab names should be truncated
        tab_size = 15,
        diagnostics = "nvim_lsp",
        color_icons = true,
        hover = {
            enabled = true,
            delay = 200,
            reveal = {'close'}
        },
        sort_by = 'id',
    }
}

-- disable netrw at the very start of your init.lua
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- optionally enable 24-bit colour
vim.opt.termguicolors = true

require("nvim-tree").setup({
  sort_by = "case_sensitive",
  view = {
	float = {
		enable = true,
		quit_on_focus_loss = true,
		open_win_config = {
			relative = "editor",
			border = "rounded",
			width = 100,
			height = 50,
			row = (vim.o.lines - 50) * 0.5,
			col = (vim.o.columns - 100) * 0.5,
		},
	},
  },
  renderer = {
    group_empty = true,
  },
  filters = {
    dotfiles = true,
  },
  git = {
    enable = false, -- Enable Git integration in nvim-tree
    ignore = false, -- Don't ignore Git ignored files
    timeout = 500, -- Timeout for Git commands
  },
})

require("ibl").setup()
local helpers = require 'incline.helpers'
local devicons = require 'nvim-web-devicons'
require('incline').setup {
  window = {
    padding = 0,
    margin = { horizontal = 0 },
  },
  render = function(props)
    local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ':t')
    if filename == '' then
      filename = '[No Name]'
    end
    local ft_icon, ft_color = devicons.get_icon_color(filename)
    local modified = vim.bo[props.buf].modified
    return {
      ft_icon and { ' ', ft_icon, ' ', guibg = ft_color, guifg = helpers.contrast_color(ft_color) } or '',
      ' ',
      { filename, gui = modified and 'bold,italic' or 'bold' },
      ' ',
      guibg = '#44406e',
    }
  end,
}

