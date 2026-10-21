# neovim simple mode

A personal Neovim configuration with Space-based shortcuts, tmux-style window
navigation, and Rust tooling. Plugins are managed by
[lazy.nvim](https://lazy.folke.io/).

## Requirements

- Neovim **0.12 or newer**, as required by the current Treesitter API.
  Older versions stop before loading plugins.
- Git, `curl`, and network access for plugin installation and Blink's prebuilt
  fuzzy matcher.
- A C compiler for the Markdown Treesitter parsers.
- `tree-sitter` CLI **0.26.1 or newer** for parser generation (install the native
  executable, not the npm package).
- `fd`, `ripgrep` (`rg`), and `fzf` for search. On Debian/Ubuntu, if the binary
  is named `fdfind`, expose it as `fd` on `PATH`.
- For Rust: `rust-analyzer` and `rustfmt` on `PATH`.
- For Python: `pyright-langserver` on `PATH` (provided by Pyright).
- A system clipboard provider for `+` register copy/paste; a Nerd Font for icons.

Language servers and external tools are installed separately. C/C++ and Lua
language servers are not enabled by this configuration.

## Install

From the repository root:

```sh
bash script/setup_init_file.sh
nvim --headless '+Lazy! restore' +qa
nvim
```

The setup script also works from another directory when invoked by its full path.
It links this repository's `nvim/` directory to
`${XDG_CONFIG_HOME:-$HOME/.config}/nvim`; keep the repository at that location.
lazy.nvim bootstraps automatically. `Lazy restore` installs the versions recorded
in `nvim/lazy-lock.json`.

Existing configuration directories, files, and symlinks are moved to a sibling
`nvim.backup.YYYYmmdd-HHMMSS.PID` path before linking. Existing data under
`${XDG_DATA_HOME:-$HOME/.local/share}/nvim` is also backed up if it contains old
`site/pack/packer` packages. Otherwise, installed Lazy data is preserved. Backup
paths are printed, and running setup again keeps an already-correct link.

To restore a previous configuration, close Neovim, remove the newly installed
configuration symlink with `unlink`, and move the printed configuration backup
back to its original path. A data backup can be restored separately by first
moving any newly generated data directory aside. Backups are not deleted
automatically.

## Plugin maintenance

- `:Lazy` opens the plugin manager.
- `:Lazy restore` restores the committed plugin versions.
- `:Lazy update` updates plugins and the lockfile. Review and commit lockfile
  changes if those versions should be shared.
- `:checkhealth` checks installed tools and providers.
- The `markdown` and `markdown_inline` Treesitter parsers are installed for
  Markdown rendering. Other parsers are installed explicitly, for example
  `:TSInstall rust python c cpp lua bash asm`.

The historical `nvim.tar.xz` contains Packer packages and is not part of the
installation workflow. `script/setup_nvim_dump.sh` refuses that legacy archive.
If a local plugin-data snapshot is needed, `script/update_nvim_dump.sh` creates a
Lazy snapshot and replaces the archive only after compression succeeds.
`script/setup_nvim_dump.sh` restores a Lazy snapshot after backing up current
data. These scripts honor `XDG_DATA_HOME`; snapshots do not install Neovim or
external tools. `inbox/old_script/` contains historical scripts and is not used
for installation.

## Configuration

`nvim/init.lua` loads these modules in order:

| Module | Responsibility |
| --- | --- |
| `plugins.lua` | lazy.nvim bootstrap, plugin declarations, early Rust settings |
| `ui.lua` | Evergarden theme, lualine statusline, bufferline, file tree, window labels |
| `plugin_setup.lua` | Treesitter, Git signs, autopairs, hex |
| `snippets.lua` | LuaSnip and the `date` snippet |
| `lsp.lua` | LSP capabilities, diagnostics, per-buffer language shortcuts |
| `basic.lua` | Editor options, navigation, clipboard and search shortcuts |

The main plugins are FzfLua for search, blink.cmp and LuaSnip for
completion, nvim-tree for files, Gitsigns for Git changes, and rustaceanvim for
Rust. Debugging is intended to use external GDB; no DAP integration is configured.
Separate tmux, Zellij, and GitUI settings live in `dotfile/` and are not installed
by the Neovim setup script.

## Completion and Markdown

[blink.cmp](https://github.com/saghen/blink.cmp) replaces nvim-cmp and its source
adapters. It uses the stable `1.*` release line, with built-in LSP, path, buffer,
and command-line sources and the existing LuaSnip snippets. A prebuilt Rust fuzzy
matcher is downloaded automatically. Insert-mode `Enter` accepts the selected
completion, `Ctrl-Space` opens the menu/documentation, `Ctrl-n/p` selects items,
and `Ctrl-e` cancels completion or cycles an active snippet choice. `Ctrl-b/f`
scrolls completion documentation. The `:`, `/`, and `?` command lines also offer
completion; use `Tab`/`Shift-Tab` to navigate and `Ctrl-y` to accept.

[render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim)
renders Markdown headings, lists, tables, and code blocks when opening Markdown
files. Use `:RenderMarkdown toggle` to switch rendering on or off. Its in-process
LSP supplies checkbox and callout completions through Blink.
[lualine.nvim](https://github.com/nvim-lualine/lualine.nvim) provides a global
statusline with the current mode, Git branch/diff, diagnostics, filename, file
details, and cursor position, using the active theme's colors.

## Shortcuts

Leader is **Space**; local leader is `\`.

| Shortcut | Action |
| --- | --- |
| `Ctrl-h/j/k/l` | Move between windows |
| `Shift-h/l` | Previous/next buffer |
| `Space 1` … `Space 9` | Select a numbered buffer |
| `Space e` | Toggle the file tree |
| `Space ff` | Find files with fd and fuzzy-select with fzf |
| `Space fg` | Live content search with rg and fzf |
| `Space fs` | Search the whole word under the cursor with rg; fuzzy-filter results |
| `Space rg` | Live rg search initialized with the word under the cursor |
| `Space /` | Fuzzy search the current buffer |
| `gd`, `gD`, `gi`, `gr` | LSP definition, declaration, implementation, references |
| `Space rn` | LSP rename |
| `Space ca` | LSP code action; Rust-specific actions in attached Rust buffers |
| `Space cd` / `Space dr` | Render Rust diagnostics |
| `Space ce` / `Space de` | Explain a Rust error |
| `K` (Rust) | Rust hover actions |
| `Ctrl-K`, `Ctrl-L`, `Ctrl-J` (insert) | Expand snippet, jump forward/back |

Rust shortcuts are buffer-local and installed when an LSP attaches to a Rust
buffer. Normal/visual `y`, `p`, `Y`, and `P` use the system clipboard.

Searches use Neovim's current working directory (`:pwd`); use `:cd /path/to/project`
to select a project. File search uses fd, content search uses rg, and both respect
ignore files and skip hidden files by default.

In `Space fg` or `Space rg`, enter `hello` to search content, or `hello -- *.rs`
to restrict the search to Rust files. Multiple globs are supported, for example
`hello -- *.c *.h`. This separator accepts file globs, not raw rg flags such as
`-t rust`. `Space fs` matches a whole word; the live searches match substrings
by default. `Ctrl-g` toggles between live rg search and fuzzy filtering of its
results. `Ctrl-x` opens a selection in a horizontal split, `Ctrl-o`/`Ctrl-v` in a
vertical split, and `Ctrl-k`/`Ctrl-j` scroll the preview. `Ctrl-/` toggles the
preview (hidden initially by the fzf-vim profile).

## Checks

```sh
bash tests/test_install.sh
# After setup and plugin restore, using Neovim 0.12 or newer:
nvim --headless '+luafile tests/test_config.lua' +qa
nvim --headless '+luafile tests/test_search.lua' +qa
```

Installer tests use temporary HOME/XDG paths and do not replace your settings.
The Neovim check covers plugin resolution, completion capabilities, and Rust
shortcut behavior across multiple buffers, plus completion, snippets, Markdown
rendering, and the statusline.
