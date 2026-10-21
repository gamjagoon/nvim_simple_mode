# neovim simple mode

[한국어](#korean) | [English](#english) | [日本語](#japanese)

<a id="korean"></a>

## 한국어

Space 기반 단축키, tmux 방식의 창 이동, Rust 개발 도구를 갖춘 개인용 Neovim
설정입니다. 플러그인은 [lazy.nvim](https://lazy.folke.io/)으로 관리합니다.

### 요구 사항

- 현재 Treesitter API를 사용하므로 Neovim **0.12 이상**이 필요합니다.
  이전 버전에서는 플러그인을 불러오기 전에 중단합니다.
- 플러그인과 Blink의 사전 빌드된 퍼지 매처를 설치하려면 Git, `curl`, 인터넷
  연결이 필요합니다.
- Markdown Treesitter 파서 빌드용 C 컴파일러가 필요합니다.
- 파서 생성용 `tree-sitter` CLI **0.26.1 이상**이 필요합니다. npm 패키지가 아닌
  네이티브 실행 파일을 설치하세요.
- 검색에는 `fd`, `ripgrep` (`rg`), `fzf`가 필요합니다. Debian/Ubuntu에서 실행
  파일 이름이 `fdfind`라면 `PATH`에서 `fd`로 실행할 수 있게 설정하세요.
- Rust: `PATH`에 `rust-analyzer`와 `rustfmt`가 있어야 합니다.
- Python: `PATH`에 Pyright가 제공하는 `pyright-langserver`가 있어야 합니다.
- `+` 레지스터 복사·붙여넣기용 시스템 클립보드 제공자와 아이콘 표시용 Nerd
  Font가 필요합니다.

언어 서버와 외부 도구는 별도로 설치합니다. 이 설정에서는 C/C++ 및 Lua 언어
서버를 활성화하지 않습니다.

### 설치

저장소 루트에서 실행합니다.

```sh
bash script/setup_init_file.sh
nvim --headless '+Lazy! restore' +qa
nvim
```

설치 스크립트의 전체 경로를 지정하면 다른 디렉터리에서도 실행할 수 있습니다.
저장소의 `nvim/`을 `${XDG_CONFIG_HOME:-$HOME/.config}/nvim`에 심볼릭 링크로
연결하므로 설치 후에도 저장소 위치를 유지하세요. lazy.nvim은 자동으로 설치되며,
`Lazy restore`는 `nvim/lazy-lock.json`에 기록된 버전으로 플러그인을 설치합니다.

기존 설정 디렉터리·파일·심볼릭 링크는 연결 전에 같은 상위 디렉터리의
`nvim.backup.YYYYmmdd-HHMMSS.PID` 경로로 옮겨 보존합니다.
`${XDG_DATA_HOME:-$HOME/.local/share}/nvim`에 과거 `site/pack/packer` 패키지가
있으면 데이터도 백업합니다. 그 외의 기존 Lazy 데이터는 유지합니다. 백업 경로는
출력되며, 다시 실행해도 이미 올바르게 연결된 링크는 유지합니다.

이전 설정을 복구하려면 Neovim을 닫고 `unlink`로 새 설정 심볼릭 링크를 제거한
뒤, 출력된 설정 백업을 원래 경로로 옮기세요. 데이터 백업은 새로 생성된 데이터
디렉터리를 다른 위치로 옮긴 뒤 별도로 복구할 수 있습니다. 백업은 자동 삭제하지
않습니다.

### 플러그인 관리

- `:Lazy`: 플러그인 관리자 열기
- `:Lazy restore`: 커밋된 플러그인 버전 복구
- `:Lazy update`: 플러그인과 lockfile 갱신. 공유할 버전이라면 lockfile 변경을
  검토하고 커밋하세요.
- `:checkhealth`: 설치된 도구와 제공자 점검
- Markdown 렌더링용 `markdown`, `markdown_inline` Treesitter 파서는 자동으로
  설치합니다. 다른 파서는 `:TSInstall rust python c cpp lua bash asm`처럼
  명시적으로 설치합니다.

과거의 `nvim.tar.xz`에는 Packer 패키지가 들어 있으며 현재 설치 과정에서는
사용하지 않습니다. `script/setup_nvim_dump.sh`는 이 과거 덤프의 복원을 거부합니다.
로컬 플러그인 데이터 스냅샷이 필요하면 `script/update_nvim_dump.sh`를 사용하세요.
Lazy 데이터 압축에 성공한 뒤에만 기존 압축 파일을 교체합니다.
`script/setup_nvim_dump.sh`는 현재 데이터를 백업한 뒤 Lazy 스냅샷을 복원합니다.
두 스크립트는 `XDG_DATA_HOME`을 따르며, 스냅샷에는 Neovim 실행 파일이나 외부
도구 설치 기능이 없습니다. `inbox/old_script/`는 과거 스크립트 보관용이며 현재
설치에는 사용하지 않습니다.

### 설정 구성

`nvim/init.lua`는 다음 순서로 모듈을 불러옵니다.

| 모듈 | 역할 |
| --- | --- |
| `plugins.lua` | lazy.nvim 자동 설치, 플러그인 선언, 초기 Rust 설정 |
| `ui.lua` | Evergarden 테마, lualine 상태줄, 버퍼 탭, 파일 트리, 창별 파일명 |
| `plugin_setup.lua` | Treesitter, Git 변경 표시, 괄호 자동 완성, hex |
| `snippets.lua` | LuaSnip과 `date` 스니펫 |
| `lsp.lua` | LSP 기능 협상, 진단, 버퍼별 언어 단축키 |
| `basic.lua` | 편집기 옵션, 이동, 클립보드, 검색 단축키 |

주요 플러그인은 검색용 FzfLua, 자동 완성용 blink.cmp·LuaSnip, 파일 탐색용
nvim-tree, Git 변경 표시용 Gitsigns, Rust 개발용 rustaceanvim입니다. 디버깅은
외부 GDB 사용을 전제로 하며 DAP 연동은 설정하지 않았습니다. tmux·Zellij·GitUI
설정은 `dotfile/`에 별도로 보관하며 Neovim 설치 스크립트로 설치하지 않습니다.

### 자동 완성 및 Markdown

[blink.cmp](https://github.com/saghen/blink.cmp)는 nvim-cmp와 개별 완성 소스를
대체합니다. 안정판 `1.*`를 사용하며 LSP·경로·버퍼·명령줄 완성 소스와 기존
LuaSnip 스니펫을 연결합니다. 사전 빌드된 Rust 퍼지 매처는 자동으로 다운로드합니다.
입력 모드에서 `Enter`로 선택 항목을 확정하고, `Ctrl-Space`로 완성 메뉴·문서를
열며, `Ctrl-n/p`로 항목을 선택합니다. `Ctrl-e`는 완성을 취소하거나 활성 스니펫의
선택지를 바꿉니다. `Ctrl-b/f`는 완성 문서를 스크롤합니다. `:`, `/`, `?` 명령줄에서도
완성을 제공하며 `Tab`/`Shift-Tab`으로 이동하고 `Ctrl-y`로 확정합니다.

[render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim)은
Markdown 파일의 제목·목록·표·코드 블록을 렌더링합니다. `:RenderMarkdown toggle`로
렌더링을 켜거나 끕니다. Neovim 내부에서 실행되는 LSP를 통해 Blink에 체크박스와
콜아웃 완성을 제공합니다.
[lualine.nvim](https://github.com/nvim-lualine/lualine.nvim)은 현재 테마 색상에 맞춘
전역 상태줄에 모드, Git 브랜치·변경, 진단, 파일명·파일 정보, 커서 위치를 표시합니다.

[hlchunk.nvim](https://github.com/shellRaining/hlchunk.nvim)은 들여쓰기 선과 커서가
위치한 코드 블록을 강조합니다. 표시가 겹치지 않도록 indent-blankline을 대체합니다.
코드 블록 강조에는 해당 언어의 Treesitter 파서가 필요합니다. 필요한 파서는
`:TSInstall lua rust python c cpp`로 설치하세요.

### 단축키

Leader는 **Space**, local leader는 `\`입니다.

| 단축키 | 동작 |
| --- | --- |
| `Ctrl-h/j/k/l` | 창 사이 이동 |
| `Shift-h/l` | 이전·다음 버퍼 |
| `Space 1` … `Space 9` | 번호로 버퍼 선택 |
| `Space e` | 파일 트리 열기·닫기 |
| `Space ff` | fd로 파일을 찾고 fzf로 퍼지 선택 |
| `Space fg` | rg·fzf로 내용 실시간 검색 |
| `Space fs` | 커서 단어를 완전 일치 단어로 검색하고 결과를 퍼지 필터링 |
| `Space rg` | 커서 단어를 초기 검색어로 넣어 rg 실시간 검색 |
| `Space /` | 현재 버퍼 퍼지 검색 |
| `gd`, `gD`, `gi`, `gr` | LSP 정의·선언·구현·참조 이동 |
| `Space rn` | LSP 이름 변경 |
| `Space ca` | LSP 코드 액션. LSP가 연결된 Rust 버퍼에서는 Rust 전용 액션 |
| `Space cd` / `Space dr` | Rust 진단 표시 |
| `Space ce` / `Space de` | Rust 오류 설명 |
| `K` (Rust) | Rust hover 액션 |
| `Ctrl-K`, `Ctrl-L`, `Ctrl-J` (입력 모드) | 스니펫 확장, 다음·이전 위치 이동 |

Rust 단축키는 Rust 버퍼에 LSP가 연결될 때 해당 버퍼에만 등록합니다.
일반·비주얼 모드의 `y`, `p`, `Y`, `P`는 시스템 클립보드를 사용합니다.

검색 기준은 Neovim의 현재 작업 디렉터리(`:pwd`)입니다. `:cd /path/to/project`로
프로젝트를 선택하세요. 파일 검색은 fd, 내용 검색은 rg를 사용하며, 둘 다 ignore
파일을 따르고 기본적으로 숨김 파일을 제외합니다.

`Space fg`·`Space rg`에서 `hello`는 내용 검색, `hello -- *.rs`는 Rust 파일로 범위를
제한한 검색입니다. `hello -- *.c *.h`처럼 여러 glob도 사용할 수 있습니다.
구분자 뒤에는 파일 glob을 넣으며 `-t rust` 같은 rg 옵션을 직접 넣는 방식은
지원하지 않습니다. `Space fs`는 완전 일치 단어를 검색하고 실시간 검색은 기본적으로
부분 문자열을 검색합니다. `Ctrl-g`로 rg 실시간 검색과 결과 퍼지 필터링을 전환합니다.
`Ctrl-x`로 가로 분할, `Ctrl-o`/`Ctrl-v`로 세로 분할하여 열고, `Ctrl-k`/`Ctrl-j`로
미리보기를 스크롤합니다. `Ctrl-/`로 미리보기를 전환합니다. fzf-vim 프로필에서는
미리보기가 처음에 숨겨져 있습니다.

### 검증

```sh
bash tests/test_install.sh
# After setup and plugin restore, using Neovim 0.12 or newer:
nvim --headless '+luafile tests/test_config.lua' +qa
nvim --headless '+luafile tests/test_search.lua' +qa
```

설치 테스트는 임시 HOME/XDG 경로를 사용하므로 실제 설정을 교체하지 않습니다.
Neovim 검사는 플러그인 구성, 완성 기능 협상, 여러 버퍼에서의 Rust 단축키,
자동 완성·스니펫, Markdown 렌더링, 상태줄을 확인합니다.

---

<a id="english"></a>

## English

A personal Neovim configuration with Space-based shortcuts, tmux-style window
navigation, and Rust tooling. Plugins are managed by
[lazy.nvim](https://lazy.folke.io/).

### Requirements

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

### Install

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

### Plugin maintenance

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

### Configuration

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

### Completion and Markdown

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

[hlchunk.nvim](https://github.com/shellRaining/hlchunk.nvim) shows indentation
guides and highlights the code block around the cursor. It replaces
indent-blankline to avoid overlapping guides. Block highlighting uses the
Treesitter parser for the file's language; install missing parsers with
`:TSInstall lua rust python c cpp` as needed.

### Shortcuts

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

### Checks

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

---

<a id="japanese"></a>

## 日本語

Space キーを使ったショートカット、tmux 風のウィンドウ移動、Rust 向けの開発環境を備えた個人用 Neovim 設定です。
プラグインは [lazy.nvim](https://lazy.folke.io/) で管理します。

### 必要なもの

- 現在の Treesitter API に必要な **Neovim 0.12 以降**。
  古いバージョンではプラグインを読み込む前に処理を停止します。
- プラグインのインストールと Blink のビルド済みファジーマッチャーの取得に使う Git、`curl`、ネットワーク接続。
- Markdown の Treesitter パーサーをビルドするための C コンパイラー。
- パーサーの生成に使う **`tree-sitter` CLI 0.26.1 以降**
  （npm パッケージではなく、ネイティブ実行ファイルをインストールしてください）。
- 検索用の `fd`、`ripgrep`（`rg`）、`fzf`。Debian/Ubuntu で実行ファイル名が
  `fdfind` の場合は、`PATH` 上で `fd` として実行できるようにしてください。
- Rust 用：`PATH` 上の `rust-analyzer` と `rustfmt`。
- Python 用：`PATH` 上の `pyright-langserver`（Pyright に含まれます）。
- `+` レジスターによるコピーと貼り付けに使うシステムクリップボードプロバイダーと、アイコン表示用の Nerd Font。

言語サーバーと外部ツールは別途インストールしてください。
この設定では C/C++ と Lua の言語サーバーを有効にしていません。

### インストール

リポジトリのルートで実行します。

```sh
bash script/setup_init_file.sh
nvim --headless '+Lazy! restore' +qa
nvim
```

セットアップスクリプトは、絶対パスで指定すれば別のディレクトリからも実行できます。
このリポジトリの `nvim/` ディレクトリへのリンクを
`${XDG_CONFIG_HOME:-$HOME/.config}/nvim` に作成するため、リポジトリは移動せずに保管してください。
lazy.nvim は自動的に導入されます。`Lazy restore` は `nvim/lazy-lock.json` に記録されたバージョンをインストールします。

既存の設定ディレクトリ、ファイル、シンボリックリンクは、リンクを作成する前に同じ親ディレクトリ内の
`nvim.backup.YYYYmmdd-HHMMSS.PID` へ移動します。
`${XDG_DATA_HOME:-$HOME/.local/share}/nvim` の既存データに古い `site/pack/packer` パッケージが含まれる場合は、
そのデータもバックアップします。それ以外の場合は、インストール済みの Lazy データを保持します。
バックアップ先のパスは画面に表示されます。セットアップを再実行しても、正しいリンクはそのまま保持します。

以前の設定に戻すには、Neovim を終了し、今回作成した設定のシンボリックリンクを `unlink` で削除してから、
表示された設定のバックアップを元のパスへ戻してください。
データのバックアップは、新しく生成されたデータディレクトリを先に別の場所へ移動すると、個別に復元できます。
バックアップは自動では削除しません。

### プラグインの管理

- `:Lazy` でプラグインマネージャーを開きます。
- `:Lazy restore` でコミット済みのプラグインバージョンを復元します。
- `:Lazy update` でプラグインとロックファイルを更新します。
  更新後のバージョンを共有する場合は、ロックファイルの変更を確認してコミットしてください。
- `:checkhealth` でインストール済みのツールとプロバイダーを確認します。
- Markdown の描画用に `markdown` と `markdown_inline` の Treesitter パーサーをインストールします。
  それ以外のパーサーは、`:TSInstall rust python c cpp lua bash asm` などで明示的にインストールしてください。

従来の `nvim.tar.xz` には Packer のパッケージが含まれており、現在のインストール手順では使用しません。
`script/setup_nvim_dump.sh` は、この旧形式のアーカイブを受け付けません。
ローカルにプラグインデータのスナップショットが必要な場合は、`script/update_nvim_dump.sh` が Lazy のスナップショットを作成し、
圧縮が成功した場合にのみアーカイブを置き換えます。
`script/setup_nvim_dump.sh` は現在のデータをバックアップしてから Lazy のスナップショットを復元します。
これらのスクリプトは `XDG_DATA_HOME` を使用します。スナップショットから Neovim 本体や外部ツールはインストールされません。
`inbox/old_script/` には過去のスクリプトがあり、インストールには使用しません。

### 設定の構成

`nvim/init.lua` は、次のモジュールを順に読み込みます。

| モジュール | 役割 |
| --- | --- |
| `plugins.lua` | lazy.nvim の導入、プラグインの宣言、Rust の初期設定 |
| `ui.lua` | Evergarden テーマ、lualine ステータスライン、bufferline、ファイルツリー、ウィンドウラベル |
| `plugin_setup.lua` | Treesitter、Git の変更サイン、autopairs、hex |
| `snippets.lua` | LuaSnip と `date` スニペット |
| `lsp.lua` | LSP の機能設定、診断、バッファーごとの言語用ショートカット |
| `basic.lua` | エディターのオプション、移動、クリップボードと検索のショートカット |

主なプラグインは、検索用の FzfLua、補完用の blink.cmp と LuaSnip、ファイル操作用の nvim-tree、
Git の変更表示用の Gitsigns、Rust 用の rustaceanvim です。
デバッグには外部の GDB を使用する想定で、DAP 連携は設定していません。
tmux、Zellij、GitUI の個別設定は `dotfile/` にあり、Neovim のセットアップスクリプトではインストールしません。

### 補完と Markdown

[blink.cmp](https://github.com/saghen/blink.cmp) は、nvim-cmp とその補完ソース用アダプターを置き換えます。
安定版の `1.*` 系列を使用し、組み込みの LSP、パス、バッファー、コマンドラインの補完ソースと、既存の LuaSnip スニペットを利用します。
ビルド済みの Rust ファジーマッチャーは自動的にダウンロードされます。
挿入モードでは、`Enter` で選択中の補完を確定し、`Ctrl-Space` でメニューやドキュメントを開き、`Ctrl-n/p` で候補を選択します。
`Ctrl-e` は補完をキャンセルするか、アクティブなスニペットの選択肢を切り替えます。
`Ctrl-b/f` で補完のドキュメントをスクロールします。
`:`, `/`, `?` のコマンドラインでも補完を利用でき、`Tab`/`Shift-Tab` で候補を移動し、`Ctrl-y` で確定します。

[render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim) は、Markdown ファイルを開くと、
見出し、リスト、表、コードブロックを描画します。`:RenderMarkdown toggle` で描画を切り替えます。
プロセス内で動作する LSP が、Blink 経由でチェックボックスとコールアウトの補完を提供します。
[lualine.nvim](https://github.com/nvim-lualine/lualine.nvim) は、現在のテーマの色を使った共通のステータスラインに、
現在のモード、Git ブランチと差分、診断、ファイル名、ファイル情報、カーソル位置を表示します。

[hlchunk.nvim](https://github.com/shellRaining/hlchunk.nvim) は、インデントガイドを表示し、カーソルを囲むコードブロックを強調表示します。
ガイドが重ならないよう、indent-blankline を置き換えます。
ブロックの強調表示には、そのファイルの言語に対応する Treesitter パーサーを使用します。
必要に応じて `:TSInstall lua rust python c cpp` で不足しているパーサーをインストールしてください。

### ショートカット

Leader は **Space**、local leader は `\` です。

| ショートカット | 操作 |
| --- | --- |
| `Ctrl-h/j/k/l` | ウィンドウ間を移動 |
| `Shift-h/l` | 前／次のバッファーへ移動 |
| `Space 1` … `Space 9` | 番号でバッファーを選択 |
| `Space e` | ファイルツリーの表示を切り替え |
| `Space ff` | fd でファイルを検索し、fzf であいまい検索して選択 |
| `Space fg` | rg と fzf で内容をリアルタイム検索 |
| `Space fs` | カーソル位置の単語を rg で単語全体として検索し、結果をあいまい検索で絞り込む |
| `Space rg` | カーソル位置の単語を初期値として rg のリアルタイム検索を開始 |
| `Space /` | 現在のバッファーをあいまい検索 |
| `gd`, `gD`, `gi`, `gr` | LSP の定義、宣言、実装、参照へ移動 |
| `Space rn` | LSP による名前変更 |
| `Space ca` | LSP コードアクション。LSP 接続済みの Rust バッファーでは Rust 固有のアクション |
| `Space cd` / `Space dr` | Rust の診断を表示 |
| `Space ce` / `Space de` | Rust のエラーの説明を表示 |
| `K`（Rust） | Rust のホバーアクション |
| `Ctrl-K`, `Ctrl-L`, `Ctrl-J`（挿入モード） | スニペットの展開、次／前の位置へジャンプ |

Rust のショートカットはバッファーごとに設定され、Rust バッファーに LSP が接続したときに有効になります。
ノーマル／ビジュアルモードの `y`、`p`、`Y`、`P` はシステムクリップボードを使用します。

検索対象は Neovim の現在の作業ディレクトリ（`:pwd`）です。`:cd /path/to/project` でプロジェクトを選択してください。
ファイル検索には fd、内容検索には rg を使用します。どちらも除外設定ファイルに従い、既定では隠しファイルを検索しません。

`Space fg` または `Space rg` では、`hello` と入力すると内容を検索し、`hello -- *.rs` と入力すると Rust ファイルに限定します。
`hello -- *.c *.h` のように、複数の glob パターンも指定できます。
この区切りの後に指定できるのはファイルの glob パターンで、`-t rust` などの rg のオプションは指定できません。
`Space fs` は単語全体に一致するものを検索し、リアルタイム検索は既定で部分一致を使用します。
`Ctrl-g` で rg のリアルタイム検索と、その結果のあいまい検索による絞り込みを切り替えます。
`Ctrl-x` で選択項目を上下分割、`Ctrl-o`/`Ctrl-v` で左右分割のウィンドウに開き、`Ctrl-k`/`Ctrl-j` でプレビューをスクロールします。
`Ctrl-/` でプレビューの表示を切り替えます（fzf-vim プロファイルでは初期状態で非表示です）。

### 動作確認

```sh
bash tests/test_install.sh
# After setup and plugin restore, using Neovim 0.12 or newer:
nvim --headless '+luafile tests/test_config.lua' +qa
nvim --headless '+luafile tests/test_search.lua' +qa
```

インストーラーのテストは一時的な HOME/XDG パスを使用するため、既存の設定を置き換えません。
Neovim のテストでは、プラグインの読み込み、補完機能、複数バッファーでの Rust ショートカットの動作に加え、
補完、スニペット、Markdown の描画、ステータスラインを確認します。
