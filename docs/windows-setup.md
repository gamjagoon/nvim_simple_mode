# earlgrey.nvim · Windows 설치

[← earlgrey.nvim README](../README.md#windows-downloads)

Windows 10/11 x64, PowerShell 5.1 이상을 대상으로 합니다. WSL에서는 Linux 설치기를 사용하세요.
Windows 구성은 **LLVM-MinGW UCRT + Rust `windows-gnullvm`**을 사용합니다.
Visual Studio Build Tools·MSVC·Microsoft Windows SDK를 설치하거나 검색하지 않습니다.
기존 Visual Studio 설치를 삭제하지도 않습니다. 일반 `LLVM.LLVM` 패키지는 이 도구 모음의 대체품이 아닙니다.

## WinGet 자동 설치

Windows의 [App Installer / WinGet](https://learn.microsoft.com/windows/package-manager/winget/)가 필요합니다.
저장소 루트에서 실행합니다.

```powershell
# 도구 + 설정 + 플러그인/파서 + 검증
powershell -NoProfile -ExecutionPolicy Bypass -File .\script\install-windows.ps1 -InstallTools
# 도구만 설치
powershell -NoProfile -ExecutionPolicy Bypass -File .\script\install-tools-windows.ps1
# 실제 설치 없이 계획 확인
powershell -NoProfile -ExecutionPolicy Bypass -File .\script\install-windows.ps1 -InstallTools -WhatIf
```

`winget` 소스에서 정확한 ID로 최신 제공 버전을 설치·갱신하며 패키지/소스 약관에 자동 동의합니다.
일부 설치기는 UAC 승인을 요청할 수 있습니다. 재부팅을 자동으로 실행하지 않으며,
재부팅이 필요한 설치 상태는 오류로 보고합니다.

| 도구 | winget ID |
| --- | --- |
| Neovim | `Neovim.Neovim` |
| Git | `Git.Git` |
| curl | `cURL.cURL` |
| fd | `sharkdp.fd` |
| ripgrep | `BurntSushi.ripgrep.MSVC` |
| fzf | `junegunn.fzf` |
| tree-sitter CLI | `tree-sitter.tree-sitter-cli` |
| Node.js LTS/npm | `OpenJS.NodeJS.LTS` |
| LLVM-MinGW UCRT | `MartinStorsjo.LLVM-MinGW.UCRT` |
| Rustup | `Rustlang.Rustup` |

ID는 [공식 winget 패키지 저장소](https://github.com/microsoft/winget-pkgs)에서 확인했습니다.
WinGet 인덱스 반영 시점에 따라 제공 버전은 달라질 수 있습니다.
ripgrep 패키지명의 `MSVC`는 배포 바이너리의 종류입니다. 개발용 MSVC 컴파일러를 설치하는 항목이 아닙니다.

설치기는 현재 프로세스의 PATH를 갱신합니다. LLVM-MinGW의 전체 `bin` 디렉터리는 WinGet 패키지가 PATH에 등록합니다.
사용자가 저장한 PATH를 스크립트에서 덮어쓰지 않습니다. 도구만 별도 `powershell -File` 프로세스에서
설치했다면 다음 작업은 새 터미널에서 실행하세요. 통합 `-InstallTools` 설치는 같은 프로세스의 갱신된 PATH를 사용합니다.

## Rust와 컴파일러 선택

신규 Rustup 설치에는 `--default-host x86_64-pc-windows-gnullvm`을 전달해 MSVC 설치 안내 경로를 피합니다.
기존 Rustup이 있으면 rustup-init 재설치를 건너뛰고 설치된 Rustup을 재사용합니다.
전역 기본 호스트·툴체인을 바꾸지 않고 아래 툴체인을 추가 설치합니다.
설정이 남아 있는데 Rustup 실행 파일을 찾지 못하면 기존 설정을 덮어쓰지 않고 중단합니다.

```powershell
rustup toolchain install stable-x86_64-pc-windows-gnullvm --profile minimal --component rust-analyzer --component rustfmt --component rust-mingw
npm install --global pyright
```

설치기와 Neovim은 자신의 프로세스 안에서 `RUSTUP_TOOLCHAIN=stable-x86_64-pc-windows-gnullvm`을 선택합니다.
따라서 Neovim에서 시작한 Rust 도구도 이 stable 호스트를 사용합니다. 별도 프로젝트의 Rust 버전/호스트를
사용하려면 이 선택과 프로젝트 설정의 호환성을 따로 확인해야 합니다. 전역 `rustup default`는 변경하지 않습니다.

`windows-compiler.ps1`은 다음을 설정합니다.

- `x86_64-w64-mingw32-clang.exe`, `x86_64-w64-mingw32-clang++.exe`를 선택합니다.
- GNU x64 대상과 `libucrt.a` 경로를 확인합니다. MSVC용 일반 clang을 허용하지 않습니다.
- `CC`·`CXX` 및 대상별 컴파일러 변수를 설정하고 Cargo의 gnullvm 링커를 같은 C 드라이버로 지정합니다.
- MSVC 호스트로 빌드된 tree-sitter CLI의 자동 대상 플래그를 덮어쓰도록,
  MSVC 대상별 `CFLAGS`·`CXXFLAGS` 마지막에 `--target=x86_64-w64-windows-gnu`를 추가합니다.
  기존 사용자 플래그는 유지합니다. [Tree-sitter loader](https://github.com/tree-sitter/tree-sitter/blob/10eb5ac119eec9cb4267a8e035066473983f5f3a/crates/loader/src/loader.rs#L1241-L1320),
  [cc-rs의 플래그 순서](https://github.com/rust-lang/cc-rs/blob/25fa77c122f3a955015f3293cd616e97bda94f1d/src/lib.rs#L2480-L2486).

새로 연 Neovim도 `compat.lua`에서 같은 환경을 구성하므로, 나중에 파서를 갱신할 때도 적용됩니다.
이 설정은 Windows 프로세스에만 적용하며 Linux/macOS 컴파일러 환경은 바꾸지 않습니다.

## 수동 설치와 검사

도구를 직접 준비한다면 다음 공식 페이지를 사용합니다.

- [LLVM-MinGW 릴리스](https://github.com/mstorsjo/llvm-mingw/releases): Windows x86_64 **UCRT** ZIP 전체를 풉니다.
  `bin`을 PATH에 추가하거나 `LLVM_MINGW_ROOT`를 `bin`의 부모 폴더로 지정합니다.
- [Rustup](https://rust-lang.github.io/rustup/installation/windows.html): 설치 시 GNU LLVM 호스트를 선택하고 위 툴체인을 설치합니다.
  [gnullvm 플랫폼 안내](https://doc.rust-lang.org/rustc/platform-support/windows-gnullvm.html)를 참고하세요.
- [Neovim](https://github.com/neovim/neovim/releases/latest), [tree-sitter](https://github.com/tree-sitter/tree-sitter/releases/latest),
  [fd](https://github.com/sharkdp/fd/releases/latest), [ripgrep](https://github.com/BurntSushi/ripgrep/releases/latest),
  [fzf](https://github.com/junegunn/fzf/releases/latest), [Git](https://git-scm.com/install/windows),
  [curl](https://curl.se/windows/), [Node.js LTS](https://nodejs.org/en/download).

Neovim ZIP은 runtime을 포함한 전체 폴더를 유지합니다. LLVM-MinGW도 실행 파일만 따로 옮기지 않습니다.
Rust 도구는 보통 `%USERPROFILE%\.cargo\bin`, Pyright는 `%APPDATA%\npm`에 설치됩니다.
최소 버전은 Neovim 0.12, tree-sitter 0.26.1, fzf 0.52.1입니다.

```powershell
# 현재 PowerShell에서 환경 선택 후 읽기 전용 검사
. .\script\windows-compiler.ps1
Initialize-WindowsCompiler
.\script\check-tools-windows.ps1
# 기존 도구로 설정과 플러그인 설치 (컴파일러 환경은 자동 초기화)
.\script\install-windows.ps1
```

점검기는 컴파일러 대상/UCRT 라이브러리, Rust 활성 툴체인과 `rustc -vV` 호스트를 확인합니다.
헤더·라이브러리 환경을 MSVC에서 가져오거나 전역 설정을 수정하지 않습니다.
버전·경로 확인은 실제 컴파일 증거가 아니며, 뒤의 Markdown 파서 빌드와 시작 검사에서 추가 검증합니다.
`-WhatIf`는 외부 도구 조회·설치 없이 계획만 출력합니다. 이전 `-Compiler`·`-SkipBuildTools` 옵션은 제거했습니다.

## 설정과 플러그인 설치

Windows는 기존 설정을 타임스탬프 폴더에 백업하고 저장소 `nvim/` 전체를 `%LOCALAPPDATA%/nvim`에 복사합니다.
`XDG_CONFIG_HOME`을 지정하면 해당 경로를 사용합니다. 플러그인 소스는 Lazy가 각 환경의
`stdpath('data')/lazy`에 다운로드합니다. 다른 운영체제의 플러그인 캐시나 바이너리를 복사하지 않습니다.
Linux/macOS는 설정을 복사하는 대신 저장소 `nvim/`에 심볼릭 링크를 만듭니다. 세 플랫폼 모두 같은 플러그인 선언을 설치합니다.

로컬 `lazy-lock.json`이 없으면 `Lazy sync`, 있으면 `Lazy restore`를 실행합니다.
재설치 시 기존 Windows 설치의 lockfile은 보존합니다. lockfile은 Git 추적에서 제외됩니다.
지연 로딩 플러그인도 설치하지만 필요한 파일/명령을 사용할 때 로딩됩니다.
언어 파서는 플러그인과 별개이며 현재 자동 설치 대상은 Markdown과 Markdown inline입니다.
인터넷 연결이 필요하며, 전체 플러그인을 저장소에 묶어 제공하는 오프라인 설치기는 아닙니다.

## Windows 전용 설정과 검증 범위

- Pyright `.cmd` 런처는 `cmd.exe /d /c`로 실행합니다.
- `xxd`가 없으면 Hex 편집만 생략합니다. 비UTF-8 텍스트를 인코딩만으로 Hex 전환하지 않습니다.
- 파일 트리 팝업은 터미널 크기에 맞춥니다. CP949 파일은 필요하면 `:edit ++enc=cp949`로 명시해서 엽니다.

```powershell
powershell -NoProfile -File tests/test_install_tools_windows.ps1
powershell -NoProfile -File tests/test_install_windows.ps1
powershell -NoProfile -File tests/test_windows_compiler.ps1
```

PowerShell 7/Linux의 모의 검사는 패키지 선택, GNU 대상 플래그, Rust 호스트, 오류 중단과 설정 보존을 검사합니다.
Neovim의 Windows 분기 역시 Linux에서 모의 검사합니다. 이 결과는 실제 Windows 설치·SDK·Rust 링크·DLL 로딩의 증거가 아닙니다.
PowerShell 5.1 및 실제 Windows에서의 설치와 파서 DLL 로딩은 별도 확인이 필요합니다.

이번 변경에서는 Linux용 LLVM-MinGW `20261020`으로 Markdown/Markdown inline 소스를 교차 빌드해
Windows x64 PE DLL 생성과 `tree_sitter_markdown`·`tree_sitter_markdown_inline` export를 확인했습니다.
이 검사는 Windows용 tree-sitter CLI 실행, Windows Neovim에서의 DLL 로딩, Rust 네이티브 링크를
검증한 것은 아닙니다.
