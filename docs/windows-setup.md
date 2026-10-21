# Windows 수동 도구 설치

Windows 10/11 x64, PowerShell 5.1 이상을 대상으로 합니다. WSL에서는 Linux 설치기를 사용하세요.
아래 공식 페이지에서 **최신 안정 릴리스**를 직접 설치한 뒤, Neovim 설정 설치기를 실행합니다.
Windows 스크립트는 도구 다운로드·설치나 PATH 변경을 수행하지 않습니다.

| 도구 | 공식 다운로드/설치 안내 | 선택할 항목 |
| --- | --- | --- |
| Neovim | [Latest release](https://github.com/neovim/neovim/releases/latest) | Windows x64 ZIP 또는 설치 파일. ZIP은 전체 폴더를 보존하고 `bin`을 PATH에 추가 |
| tree-sitter CLI | [Latest release](https://github.com/tree-sitter/tree-sitter/releases/latest) | `tree-sitter-windows-x64.gz`를 풀어 `tree-sitter.exe`로 저장. npm 패키지 대신 네이티브 CLI 사용 |
| fd | [Latest release](https://github.com/sharkdp/fd/releases/latest) | Windows x64 MSVC ZIP에서 `fd.exe` 추출 |
| ripgrep | [Latest release](https://github.com/BurntSushi/ripgrep/releases/latest) | Windows x64 MSVC ZIP에서 `rg.exe` 추출 |
| fzf | [Latest release](https://github.com/junegunn/fzf/releases/latest) | Windows amd64 ZIP에서 `fzf.exe` 추출 |
| Git | [Git for Windows](https://git-scm.com/install/windows) | 최신 x64 설치 프로그램, 명령줄에서 Git 사용 옵션 선택 |
| curl | [Windows downloads](https://curl.se/windows/) | 기존 `curl.exe`가 있으면 사용 가능. 추가 설치 시 x64 선택 |
| Node.js/npm | [Download](https://nodejs.org/en/download) | 최신 LTS Windows x64 설치 프로그램. npm 및 PATH 옵션 포함 |
| Rust/rustup | [Install Rust](https://rust-lang.org/tools/install/) | x64 `rustup-init.exe`, stable 툴체인 설치 |
| LLVM/Clang | [Latest release](https://github.com/llvm/llvm-project/releases/latest) | Windows x64 설치 프로그램, LLVM `bin`을 PATH에 추가 |
| MSVC/Windows SDK | [C++ Build Tools](https://visualstudio.microsoft.com/visual-cpp-build-tools/) | "Desktop development with C++" 워크로드와 Windows SDK 선택 |
| Pyright | [공식 설치 안내](https://github.com/microsoft/pyright#command-line) | Node.js 설치 후 아래 npm 명령 실행 |
| Nerd Font (선택) | [Downloads](https://www.nerdfonts.com/font-downloads) | 설치 후 터미널 글꼴로 지정하면 아이콘 표시 |

독립 실행 파일은 예를 들어 `%LOCALAPPDATA%\Programs\nvim-tools\bin` 같은
사용자 폴더에 보관하고, Windows의 **환경 변수 → 사용자 Path**에 해당 폴더를 추가하세요.
Neovim ZIP은 실행 파일만 옮기지 말고 함께 제공되는 runtime 파일을 유지해야 합니다.
기존 시스템 PATH의 오래된 도구가 먼저 선택된다면 해당 설치를 갱신하거나 PATH 순서를 정리하세요.

Rustup/Node.js 설치 후 새 PowerShell 창에서 필요한 언어 도구를 설치합니다.
특정 버전 번호 없이 현재 stable 툴체인과 npm의 최신 Pyright를 사용합니다.

```powershell
rustup update stable
# 기본 툴체인이 없다면 먼저 실행: rustup default stable
rustup component add rust-analyzer rustfmt
npm install --global pyright
```

`rustup component add`는 현재 선택된 툴체인에 적용됩니다. 별도의 툴체인을 사용한다면
그 툴체인에 해당 컴포넌트가 제공되는지 확인하세요.
`rust-analyzer.exe`/`rustfmt.exe`는 보통 `%USERPROFILE%\.cargo\bin`,
`pyright-langserver.cmd`는 보통 `%APPDATA%\npm`에 생성됩니다.

PowerShell을 새로 열고 저장소 루트에서 실행합니다.

```powershell
# 공식 URL과 설치 상태 점검: 파일이나 PATH를 변경하지 않음
powershell -NoProfile -ExecutionPolicy Bypass -File .\script\check-tools-windows.ps1

# 필요한 도구가 모두 준비되면 설정 백업/복사, 플러그인/파서 설치, 시작 검사
powershell -NoProfile -ExecutionPolicy Bypass -File .\script\install-windows.ps1
```

도구 링크만 확인하려면 점검기에 `-WhatIf`를 붙입니다.
설정 설치기에 `-WhatIf`를 붙이면 설정 복사와 플러그인 설치 계획만 확인합니다.
최소 지원 버전(Neovim 0.12, tree-sitter 0.26.1, fzf 0.36)은 호환성 검사에만 사용하며
다운로드 버전을 고정하지 않습니다. 설정 설치기는 도구 업데이트를 대신 수행하지 않습니다.
