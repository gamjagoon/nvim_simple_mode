# Scatch

## Concepts
1. Maintains a user-friendly concept similar to tmux, carrying over the settings from tmux.
2. The basic combination uses space. The Leader key is used for important settings and short-range mapping.
3. Unnecessary plugins are excluded.
4. Only gdb will be used for debugging…

## Plugins

### Plugin importer
Plugin Import and Installer
https://github.com/wbthomason/packer.nvim

```sh
git clone --depth 1 https://github.com/wbthomason/packer.nvim\
 ~/.local/share/nvim/site/pack/packer/start/packer.nvim
```

### Colorscheme
https://github.com/folke/tokyonight.nvim
```sh
vim.cmd[[colorscheme tokyonight]]
```

### FileTree
https://github.com/nvim-tree/nvim-tree.lua
https://github.com/nvim-tree/nvim-web-devicons

### Buffer
https://github.com/nvim-lua/popup.nvim
https://github.com/nvim-lua/plenary.nvim
https://github.com/akinsho/bufferline.nvim

### SearchFile
`telescope`를 사용해서 ripgrep을 integration함
https://github.com/nvim-telescope/telescope.nvim#pickers
https://github.com/nvim-telescope/telescope-fzf-native.nvim
https://github.com/nvim-telescope/telescope-live-grep-args.nvim

```lua
use { 'nvim-telescope/telescope-fzf-native.nvim', run = 'make' }

-- You dont need to set any of these options. These are the default ones. Only
-- the loading is important
require('telescope').setup {
  extensions = {
    fzf = {
      fuzzy = true,                    -- false will only do exact matching
      override_generic_sorter = true,  -- override the generic sorter
      override_file_sorter = true,     -- override the file sorter
      case_mode = "smart_case",        -- or "ignore_case" or "respect_case"
                                       -- the default case_mode is "smart_case"
    }
  }
}
-- To get fzf loaded and working with telescope, you need to call
-- load_extension, somewhere after setup function:
require('telescope').load_extension('fzf')
```

### Lsp
https://github.com/neovim/nvim-lspconfig
https://github.com/simrat39/rust-tools.nvim

### cmp
https://github.com/hrsh7th/nvim-cmp
https://github.com/hrsh7th/cmp-buffer
https://github.com/hrsh7th/cmp-nvim-lsp
https://github.com/hrsh7th/cmp-path
https://github.com/hrsh7th/cmp-cmdline
https://github.com/hrsh7th/cmp-calc

### autopair
https://github.com/windwp/nvim-autopairs

## ToDo
- [x] keymapping 추가하기 📅 2023-11-21 
- [x] 설치할 Plugin 조사하기 📅 2023-11-21 
- [ ] Plugin 추가 📅 2023-11-22 
