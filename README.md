<div align="center">

# earlgrey.nvim

**얼그레이 네오빔 · A warm cup. A focused editor.**

<img src="docs/assets/earlgrey-tea.png" alt="A steaming cup of amber Earl Grey tea with bergamot and tea leaves on a forest-green background" width="960">

차 한 잔의 여유로, 코드에 몰입하는 Neovim.

![Neovim 0.12+](https://img.shields.io/badge/Neovim-0.12%2B-536B4F?style=flat-square&logo=neovim&logoColor=white)
![Configured in Lua](https://img.shields.io/badge/Config-Lua-BB8749?style=flat-square&logo=lua&logoColor=white)
![Linux, macOS and Windows](https://img.shields.io/badge/Linux_%C2%B7_macOS_%C2%B7_Windows-3E5146?style=flat-square)

[한국어](#korean) · [English](#english) · [日本語](#japanese) · [Windows 다운로드 / Downloads](#windows-downloads)

</div>

---

<a id="korean"></a>

## 한국어

> 홍차처럼 차분하게, 손에 익은 도구로 편안하게.

**earlgrey.nvim**은 Space 기반 단축키, tmux 방식의 창 이동, Rust 개발 도구를
갖춘 개인용 Neovim 설정입니다. 플러그인은 [lazy.nvim](https://lazy.folke.io/)으로 관리합니다.

| 한 모금씩 살펴보기 | 구성 |
| --- | --- |
| 편안한 작업 공간 | Evergarden 테마, 상태줄, 버퍼 탭, 파일 트리 |
| 손에 익는 이동 | Space 단축키, `Ctrl-h/j/k/l` 창 이동, 번호로 버퍼 선택 |
| 빠른 파일·내용 검색 | FzfLua + `fd` + `ripgrep` |
| 자연스러운 완성 | Blink 자동 완성 + LuaSnip 스니펫 |
| Rust·Python 개발 | rustaceanvim, rust-analyzer, Pyright |
| 읽기 좋은 Markdown | 제목·목록·표·코드 블록 렌더링 |

[설치](#설치) · [단축키](#단축키) · [검증](#검증)

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

Linux/macOS 설치기는 언어 서버와 외부 도구를 함께 설치합니다. Windows는
[공식 링크 안내](docs/windows-setup.md)를 따라 직접 설치합니다. 이 설정에서는 C/C++ 및
Lua 언어 서버를 활성화하지 않습니다.

### 설치

저장소를 받은 뒤 운영체제에 맞는 명령을 실행합니다.

- Linux: Ubuntu 24.04+/Debian 12+, 현재 Fedora/Arch, x86_64 또는 arm64.
  배포판 패키지 설치에는 `sudo` 권한이 필요합니다.
- macOS: Apple Silicon 또는 기존 Homebrew가 있는 Intel Mac. Command Line Tools
  설치 창이 열리면 설치를 완료한 뒤 다시 실행하세요. 새 Homebrew 자동 설치는
  Apple Silicon을 지원합니다.
- Windows: Windows 10/11 x64, PowerShell 5.1+. 먼저
  [아래 공식 다운로드 링크](#windows-downloads)에서 도구를 설치하세요.
  PATH 설정과 설치 항목은 [Windows 수동 설치 안내](docs/windows-setup.md)를 참고하세요.

필수 도구는 Git, curl, C 도구 모음, Neovim 0.12+, native tree-sitter CLI 0.26.1+,
fd, rg, fzf 0.36+, Node/npm, Pyright, Rust 및 rust-analyzer/rustfmt입니다.
Linux는 X11/Wayland 클립보드 도구도 설치합니다. Unix의 사용자 도구 PATH는
쉘 초기화 파일에서 불러옵니다. Windows에서는 도구 설치 시 PATH를 직접 등록하고
새 터미널을 여세요. `check-tools-windows.ps1`로 실행 중인 도구와 공식 링크를
확인할 수 있습니다. 시스템 PATH의 오래된 도구가 먼저 실행된다면 해당 설치를 갱신하세요.

```sh
# Linux
bash script/install-linux.sh
# macOS
bash script/install-macos.sh
```

```powershell
# Windows PowerShell: install tools from official links first, then check and set up
powershell -NoProfile -ExecutionPolicy Bypass -File .\script\check-tools-windows.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\script\install-windows.ps1
```

Linux/macOS는 도구 설치 → 설정 백업/연결 → 플러그인 복원 → 파서 설치 →
시작·검색 검사를 수행합니다. Windows는 도구 점검 후 설정 백업/복사부터 수행합니다.
Windows 점검만 실행하려면 `check-tools-windows.ps1`을 사용하세요.
도구만 설치하려면 `install-tools-linux.sh`, `install-tools-macos.sh`를 사용합니다.
Unix에서 도구 설치를 생략하려면 `--skip-tools`를 지정합니다.
Neovim·tree-sitter는 실행 시 공식 최신 안정 릴리스를 조회하며, 설치된 버전이
이보다 오래되면 갱신합니다. 다른 도구는 패키지 관리자가 제공하는 최신 버전을 사용합니다.
최소 버전 검사는 유지하고 플러그인은 기존 lockfile로 복원합니다.
실제 변경 없이 명령을 확인하려면 Unix는 `--dry-run`, Windows는 `-WhatIf`를 사용합니다.

Linux/macOS는 저장소의 `nvim/`을 `${XDG_CONFIG_HOME:-$HOME/.config}/nvim`에
연결합니다. Windows는 관리자 권한이 필요한 심볼릭 링크 대신
`%LOCALAPPDATA%/nvim`에 복사합니다. `XDG_CONFIG_HOME`을 지정하면 해당 경로를
사용합니다. Unix에서는 저장소를 옮기지 마세요. Windows에서 저장소 설정을
변경한 뒤에는 설치기를 다시 실행해 복사본을 갱신하세요.
기본 앱 이름인 `nvim`을 사용하며, 설치 전에 별도의 `NVIM_APPNAME` 설정은 해제하세요.

기존 설정은 덮어쓰기 전에 `nvim.backup.<timestamp>...`로 옮겨 보존합니다.
기존 Packer 패키지가 있는 데이터도 별도로 백업하고, 현재 Lazy 데이터는 유지합니다.
이전 설정으로 돌아가려면 Neovim을 종료하고 새 설정을 다른 경로로 옮긴 뒤
출력된 백업 경로를 원래 위치로 복원하세요. 백업은 자동 삭제하지 않습니다.
아이콘을 표시하려면 터미널 글꼴을 Nerd Font로 별도 지정하세요.

### 플러그인 관리

- `:Lazy`: 플러그인 관리자 열기
- `:Lazy restore`: 커밋된 플러그인 버전 복구
- `:Lazy update`: 플러그인과 lockfile 갱신. 공유할 버전이라면 lockfile 변경을
  검토하고 커밋하세요.
- `:checkhealth`: 설치된 도구와 제공자 점검
- Markdown 렌더링용 `markdown`, `markdown_inline` Treesitter 파서는 자동으로
  설치합니다. 다른 파서는 `:TSInstall rust python c cpp lua bash asm`처럼
  명시적으로 설치합니다.

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

Windows 설치기 백업·실패 처리 검사는 별도 PowerShell 세션에서 실행합니다.
이 검사는 도구를 모의 실행하며 Windows 실제 도구 설치 검증과는 구분됩니다.

```powershell
powershell -NoProfile -File tests/test_install_windows.ps1
```


```sh
bash tests/test_install.sh
bash tests/test_installers.sh
bash tests/test_releases.sh
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

> Settle in with a cup of tea and tools that feel familiar.

**earlgrey.nvim** is a personal Neovim configuration with Space-based shortcuts,
tmux-style window navigation, and Rust tooling. Plugins are managed by
[lazy.nvim](https://lazy.folke.io/).

Evergarden colors, FzfLua search, Blink completion, LuaSnip snippets, and rendered
Markdown bring the workspace together. Rust uses rustaceanvim and rust-analyzer;
Python uses Pyright.

[Installation](#install) · [Key bindings](#shortcuts) · [Verification](#checks)

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

Linux/macOS installers include language servers and external tools. On Windows,
install them manually using the [official links guide](docs/windows-setup.md). C/C++ and Lua
language servers are not enabled by this configuration.

### Install

Clone the repository and run the installer for your OS:

- Linux: Ubuntu 24.04+/Debian 12+, current Fedora/Arch, x86_64 or arm64.
  Distro package installation requires `sudo` privileges.
- macOS: Apple Silicon, or Intel with an existing working Homebrew installation.
  Complete Apple's Command Line Tools dialog and rerun if prompted. Automatic
  Homebrew bootstrap supports Apple Silicon.
- Windows: Windows 10/11 x64, PowerShell 5.1+. Install tools manually from the
  [official download links below](#windows-downloads) first.
  Follow the [Windows setup guide](docs/windows-setup.md) for PATH and component selection.

Tools include Git, curl, a C toolchain, Neovim 0.12+, native tree-sitter CLI 0.26.1+,
fd, rg, fzf 0.36+, Node/npm, Pyright, Rust, rust-analyzer, and rustfmt. Linux also
installs X11/Wayland clipboard tools. Unix shell startup files load the user tool
PATH. On Windows, add tools to PATH manually and open a new terminal. Use
`check-tools-windows.ps1` to inspect resolved tools and official links. Upgrade
older system tools if Machine PATH selects them first.

```sh
# Linux
bash script/install-linux.sh
# macOS
bash script/install-macos.sh
```

```powershell
# Windows PowerShell: install tools from official links first, then check and set up
powershell -NoProfile -ExecutionPolicy Bypass -File .\script\check-tools-windows.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\script\install-windows.ps1
```

Linux/macOS installers install tools, back up/link configuration, restore plugins,
install parsers, and run startup/search checks. Windows checks manually installed
tools before backing up/copying configuration and restoring plugins.
Use `check-tools-windows.ps1` to inspect Windows prerequisites only.
Use `install-tools-linux.sh` or `install-tools-macos.sh` for tools alone, or
`--skip-tools` on Unix to keep existing tools.
Neovim and tree-sitter resolve the latest official stable release at runtime and
upgrade older installations. Other tools use the latest versions offered by their
package managers. Minimum compatibility checks remain; plugins use the lockfile. Preview commands without
changes with `--dry-run` on Unix or `-WhatIf` on Windows.

Linux/macOS link `nvim/` to `${XDG_CONFIG_HOME:-$HOME/.config}/nvim`; keep the
repository in place. Windows copies it to `%LOCALAPPDATA%/nvim` without requiring
privileged symlinks; rerun after changing the repository configuration.
`XDG_CONFIG_HOME` overrides the config root. Use the default app name `nvim` and
unset custom `NVIM_APPNAME` values before installation.

Existing configuration is moved to `nvim.backup.<timestamp>...` before replacement.
Data containing legacy Packer packages is also backed up; existing Lazy data is
retained. To restore a backup, close Neovim, move the new configuration aside, and
move the printed backup path to its original location. Backups are never deleted
automatically. Select a Nerd Font in your terminal separately for icon display.

### Plugin maintenance

- `:Lazy` opens the plugin manager.
- `:Lazy restore` restores the committed plugin versions.
- `:Lazy update` updates plugins and the lockfile. Review and commit lockfile
  changes if those versions should be shared.
- `:checkhealth` checks installed tools and providers.
- The `markdown` and `markdown_inline` Treesitter parsers are installed for
  Markdown rendering. Other parsers are installed explicitly, for example
  `:TSInstall rust python c cpp lua bash asm`.

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

Run the Windows backup/failure checks in a fresh PowerShell session. Tools are
mocked; this does not validate native Windows tool installation.

```powershell
powershell -NoProfile -File tests/test_install_windows.ps1
```


```sh
bash tests/test_install.sh
bash tests/test_installers.sh
bash tests/test_releases.sh
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

> 紅茶を片手に、使い慣れた道具で落ち着いてコードを書く。

**earlgrey.nvim** は、Space キーを使ったショートカット、tmux 風のウィンドウ移動、Rust 向けの開発環境を備えた個人用 Neovim 設定です。
プラグインは [lazy.nvim](https://lazy.folke.io/) で管理します。

Evergarden テーマ、FzfLua による検索、Blink の補完、LuaSnip のスニペット、
Markdown のレンダリングを組み合わせています。Rust には rustaceanvim と rust-analyzer、
Python には Pyright を使用します。

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

Linux/macOS のインストーラーは言語サーバーと外部ツールも導入します。
Windows は[公式リンクの案内](docs/windows-setup.md)から手動で導入します。
この設定では C/C++ と Lua の言語サーバーを有効にしていません。

### インストール

リポジトリを取得して、OS に対応するコマンドを実行します。

- Linux：Ubuntu 24.04+/Debian 12+、現在の Fedora/Arch、x86_64 または arm64。
  システムパッケージの導入には `sudo` 権限が必要です。
- macOS：Apple Silicon、または既存の Homebrew が動作する Intel Mac。
  Command Line Tools のダイアログが開いた場合は導入後に再実行してください。
  Homebrew の自動導入は Apple Silicon に対応します。
- Windows：Windows 10/11 x64、PowerShell 5.1+。最初に
  [下記の公式ダウンロードリンク](#windows-downloads)からツールを手動で導入します。
  PATH と導入項目は [Windows 手動セットアップ](docs/windows-setup.md)を参照してください。

Git、curl、C ツールチェーン、Neovim 0.12+、ネイティブ tree-sitter CLI 0.26.1+、
fd、rg、fzf 0.36+、Node/npm、Pyright、Rust、rust-analyzer、rustfmt を導入します。
Linux は X11/Wayland のクリップボードツールも導入します。Unix はシェルの
初期化ファイルを更新します。Windows は PATH を手動で設定してから新しい
ターミナルを開き、`check-tools-windows.ps1` でツールと公式リンクを確認します。
古いシステムのツールが先に選択される場合は、そのインストールを更新してください。

```sh
# Linux
bash script/install-linux.sh
# macOS
bash script/install-macos.sh
```

```powershell
# Windows PowerShell: install tools from official links first, then check and set up
powershell -NoProfile -ExecutionPolicy Bypass -File .\script\check-tools-windows.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\script\install-windows.ps1
```

Linux/macOS はツール導入、設定のバックアップとリンク、プラグイン復元、
パーサー導入、起動・検索テストを実行します。Windows は手動導入済みのツールを
確認してから、設定のバックアップ／コピーとプラグイン導入を実行します。
Windows の確認のみは `check-tools-windows.ps1` を使用します。
ツールのみは `install-tools-linux.sh`、`install-tools-macos.sh`、Unix での
ツール導入省略は `--skip-tools` を指定します。
Neovim と tree-sitter は実行時に公式の最新安定リリースを取得し、古い導入を更新します。
その他のツールはパッケージマネージャーが提供する最新版を使用します。
最低バージョンの確認は維持し、プラグインはロックファイルから復元します。
変更せずに確認するには Unix は `--dry-run`、Windows は `-WhatIf` を指定します。

Linux/macOS は `nvim/` を `${XDG_CONFIG_HOME:-$HOME/.config}/nvim` にリンクするため、
リポジトリを移動しないでください。Windows は管理者権限の必要なリンクを使わず
`%LOCALAPPDATA%/nvim` にコピーします。設定の変更後は再実行してください。
`XDG_CONFIG_HOME` で設定先を変更できます。アプリ名は既定の `nvim` を使い、
独自の `NVIM_APPNAME` は解除してください。

既存の設定は `nvim.backup.<timestamp>...` に移動して保存します。
古い Packer パッケージを含むデータもバックアップし、現在の Lazy データは維持します。
復元する場合は Neovim を終了し、新しい設定を別の場所に移動してから、
表示されたバックアップを元のパスに戻します。バックアップは自動削除しません。
アイコンを表示するには、ターミナルで Nerd Font を別途選択してください。

### プラグインの管理

- `:Lazy` でプラグインマネージャーを開きます。
- `:Lazy restore` でコミット済みのプラグインバージョンを復元します。
- `:Lazy update` でプラグインとロックファイルを更新します。
  更新後のバージョンを共有する場合は、ロックファイルの変更を確認してコミットしてください。
- `:checkhealth` でインストール済みのツールとプロバイダーを確認します。
- Markdown の描画用に `markdown` と `markdown_inline` の Treesitter パーサーをインストールします。
  それ以外のパーサーは、`:TSInstall rust python c cpp lua bash asm` などで明示的にインストールしてください。

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

Windows のバックアップ・失敗処理テストは、新しい PowerShell セッションで実行します。
外部ツールはモックのため、Windows での実際のツール導入の検証とは異なります。

```powershell
powershell -NoProfile -File tests/test_install_windows.ps1
```


```sh
bash tests/test_install.sh
bash tests/test_installers.sh
bash tests/test_releases.sh
# After setup and plugin restore, using Neovim 0.12 or newer:
nvim --headless '+luafile tests/test_config.lua' +qa
nvim --headless '+luafile tests/test_search.lua' +qa
```

インストーラーのテストは一時的な HOME/XDG パスを使用するため、既存の設定を置き換えません。
Neovim のテストでは、プラグインの読み込み、補完機能、複数バッファーでの Rust ショートカットの動作に加え、
補完、スニペット、Markdown の描画、ステータスラインを確認します。

---

<a id="windows-downloads"></a>

## Windows 다운로드 / Downloads / ダウンロード

Windows x64용 최신 안정 릴리스를 직접 설치합니다. Download the latest stable
Windows x64 releases manually. Windows x64 の最新安定リリースを手動で導入します。
자세한 설치 항목·PATH 설정 / component and PATH instructions / 詳細な設定：
[Windows setup guide](docs/windows-setup.md).

| 도구 / Tool | 공식 다운로드 / Official download |
| --- | --- |
| Neovim | [Latest release](https://github.com/neovim/neovim/releases/latest) |
| tree-sitter CLI | [Latest native CLI](https://github.com/tree-sitter/tree-sitter/releases/latest) |
| fd | [Latest release](https://github.com/sharkdp/fd/releases/latest) |
| ripgrep (`rg`) | [Latest release](https://github.com/BurntSushi/ripgrep/releases/latest) |
| fzf | [Latest release](https://github.com/junegunn/fzf/releases/latest) |
| Git | [Git for Windows](https://git-scm.com/install/windows) |
| curl | [Windows downloads](https://curl.se/windows/) |
| Node.js/npm | [Latest LTS](https://nodejs.org/en/download) |
| Rust/rustup | [Install Rust](https://rust-lang.org/tools/install/) |
| LLVM/Clang | [Latest release](https://github.com/llvm/llvm-project/releases/latest) |
| MSVC / Windows SDK | [C++ Build Tools](https://visualstudio.microsoft.com/visual-cpp-build-tools/) |
| Pyright | [Installation instructions](https://github.com/microsoft/pyright#command-line) |
| Nerd Font (optional) | [Font downloads](https://www.nerdfonts.com/font-downloads) |
