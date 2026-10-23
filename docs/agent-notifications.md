# Agent completion notifications

The optional hook installer connects agents in separate terminal windows to
`script/agent-notify.py`. Run it with the same user and environment as Neovim.
Python 3 is required; merging jcode TOML requires Python 3.11 or later.
Linux, WSL, and macOS are supported by the installer; native Windows is not.

```sh
python3 script/setup-agent-hooks.py --dry-run
python3 script/setup-agent-hooks.py
```

Only agents found on `PATH` are configured. Restart the agents after installation
(or reload Pi extensions). Run the installer again after moving this repository:
hooks reference its absolute path and the Python executable used for installation.
Existing settings and other hooks are preserved. Changed files receive timestamped
`.earlgrey-backup-*` backups; repeating installation does not add duplicate hooks.
A malformed or unusual configuration is reported without overwriting that file.
Backups can contain private settings: keep them local.

| Agent | Configuration | Event |
| --- | --- | --- |
| Claude Code | `~/.claude/settings.json` (`CLAUDE_CONFIG_DIR` respected) | `Stop`, selected `Notification`, `PreToolUse: AskUserQuestion` |
| jcode | `~/.jcode/config.toml` | `hooks.turn_end` |
| Pi | `~/.pi/agent/extensions/earlgrey-agent-notify.js` (`PI_CODING_AGENT_DIR` respected) | `agent_settled`, `ui_prompt_start` |

These events indicate a response/run ended, not that tests passed or the requested
work succeeded. Claude Stop can run before another Stop hook requests more work.
A jcode `JCODE_HOOK_TURN_END` environment override takes precedence over the installed
configuration and must be removed or updated separately.

Current Pi supports `agent_settled`, which waits for automatic continuation to stop.
For an older Pi release without that event, explicitly select the older event:

```sh
python3 script/setup-agent-hooks.py --agent pi --pi-event agent_end
```

`agent_end` can notify before retries, queued work, or compaction recovery finish.
The installer does not infer Pi event support from an unverified version number.

To remove only this integration (including when the agent is no longer installed):

```sh
python3 script/setup-agent-hooks.py --uninstall
```

The installer does not delete the repository, backups, or unrelated hooks.

Upstream contracts:
[Claude hooks](https://code.claude.com/docs/en/hooks),
[jcode lifecycle hooks](https://github.com/1jehuang/jcode/blob/master/docs/HOOKS.md),
[Pi extensions](https://github.com/badlogic/pi-mono/blob/main/packages/coding-agent/docs/extensions.md).

## 메인 에이전트와 질문 알림

완료 알림과 질문/입력 요청 알림을 구분합니다. 질문에는 `입력 필요`를 표시하고
Neovim에서는 경고색으로 보여줍니다. 모든 채널의 전송 전에 하위 에이전트인지
검사하므로 억제된 이벤트는 OS 팝업·소리·Neovim 알림 모두 발생하지 않습니다.

- Claude: `SubagentStop`은 등록하지 않습니다. `agent_id`나 하위 에이전트의
  transcript가 있는 이벤트도 무시합니다. `agent_type`만 지정된 메인
  `--agent` 세션은 정상으로 처리합니다. `AskUserQuestion` 직전과 권한 요청·
  elicitation·입력 요청 알림에 연결하며 단순 `idle_prompt`는 제외합니다.
- jcode: `JCODE_HOME` 또는 `~/.jcode`의 `sessions/{session_id}.json`에서
  `parent_id: null`인 메인 세션만 허용합니다. 하위·debug 세션과 역할 확인이
  불가능한 세션은 알리지 않습니다. 공식 hook에는 별도 질문 이벤트가 없으므로,
  자연어 질문을 남기며 턴을 종료하면 기존 `turn_end` 알림이 울립니다.
  도구 실행 중의 별도 질문 대기를 감지하는 기능은 제공하지 않습니다.
- Pi: UI가 없는 하위 프로세스에서는 hook을 실행하지 않습니다. 메인 UI의
  `ui_prompt_start`에서 입력 요청을 알립니다. 하위 에이전트를 자체 UI와 함께
  실행하는 사용자 정의 확장은 구분할 표준 필드가 없으므로, 해당 하위 프로세스에
  `EARLGREY_NOTIFY_DISABLE=1`을 설정해야 합니다. RPC/SDK 등 UI 없는 메인도
  기본적으로 알리지 않습니다. 구버전 Pi에 `ui_prompt_start`가 없으면 질문 알림은
  지원되지 않으며, 완료 이벤트 호환 옵션과 별개입니다.

이미 hook을 설치했다면 아래 명령을 다시 실행해 질문 알림 설정을 반영합니다.

```sh
python3 script/setup-agent-hooks.py
```

## Neovim 사용법

설정 반영 후 Neovim을 다시 열면 외부 터미널에서 보낸 알림을 받습니다.

| 명령 / 키 | 기능 |
| --- | --- |
| `:AgentNotifications test` | Neovim 팝업 테스트 |
| `:AgentNotifications status` | 수신 상태와 inbox 경로 |
| `:AgentNotifications off` / `on` | 현재 Neovim의 에이전트 팝업 끄기 / 켜기 |
| `Space nh` / `:Notifications` | 알림 기록 |
| `Space nd` | 표시 중인 팝업과 대기 알림 닫기 |

에이전트 팝업은 10초간 표시되고 일반 `vim.notify` 알림은 5초간 표시됩니다.
프로젝트명과 가능한 경우 세션 ID를 표시합니다. 같은 사용자의 실행 중인
모든 earlgrey.nvim 창에 전달하며, Neovim을 닫은 동안의 알림은 저장하지 않습니다.
현재 창에서 `off`를 선택해도 OS 알림과 다른 창의 알림은 계속 동작합니다.

외부 터미널에서 전체 전달 경로를 시험하려면 Neovim을 열어 둔 채 실행합니다.

```sh
python3 script/agent-notify.py --agent Test </dev/null
```

수신기는 `stdpath('state')/agent-notifications` 아래 사용자 전용 inbox를
500ms마다 확인합니다. 송신기와 Neovim은 같은 `HOME`, `XDG_STATE_HOME`,
`NVIM_APPNAME` 환경을 사용해야 합니다. SSH 원격 호스트, 컨테이너, Windows와
WSL처럼 서로 다른 파일시스템 환경 사이의 전달은 별도 연결이 필요합니다.
표준 실행에서는 GUI/터미널 UI가 연결된 Neovim만 수신기를 시작합니다.

## OS 팝업과 소리

송신기는 가능한 경우 Neovim 전달과 함께 OS 알림·소리를 실행합니다.
추가 도구가 없거나 실행에 실패해도 에이전트 작업을 중단하지 않습니다.
실행 결과의 `inboxes`, `desktop`, `sound` 값으로 전달 여부를 확인할 수 있습니다.
OS 명령 성공은 실제 사용자가 보고 들었다는 증거는 아닙니다.

- Linux: `notify-send`로 데스크톱 알림, `canberra-gtk-play` 또는 `paplay`와
  freedesktop 사운드 파일로 소리를 재생합니다. Ubuntu/Debian에서는
  `sudo apt install libnotify-bin libcanberra-gtk3-bin pulseaudio-utils sound-theme-freedesktop`으로
  관련 도구를 설치할 수 있습니다. 데스크톱 알림 서비스와 오디오 세션이 필요합니다.
- macOS: 기본 `osascript` 알림과 `afplay`의 Glass 소리를 사용합니다.
  알림 허용·집중 모드·음량 설정에 따라 실제 표시와 재생이 달라집니다.
- WSLg: `zenity`의 일반 Wayland 창으로 표시합니다. 배너 서비스가 표시 상태를
  보고해도 실제 화면에 보이지 않는 문제가 확인되어 이 경로를 우선합니다.
  Windows 알림 센터에 쌓이는 네이티브 토스트는 아닙니다. 팝업은 15초 후 닫힙니다.
  소리는 `paplay`와 WSLg의 `PulseServer`를 사용합니다.

수동 실행 시 `--no-desktop`, `--no-sound`로 선택적으로 끌 수 있습니다.
설치된 hook에도 같은 옵션을 추가할 수 있으나 재설치하면 기본값으로 돌아갑니다.

Ubuntu/Debian에서는 관리자 권한 없이 도구와 한국어 폰트를 설치할 수 있습니다.

```sh
bash script/setup-notification-tools.sh
```

Ubuntu 저장소의 패키지를 `~/.local/opt/earlgrey-notify`에 추출하고
`~/.local/bin`에 실행 래퍼를 만듭니다. 기존 실행 파일은 보존합니다.
한국어 Nanum 폰트는 `~/.local/share/fonts/earlgrey-notify`에 설치합니다.
WSLg에서는 Wayland 창을 사용하고, 일반 Linux에서는 기존 알림 서비스를
사용하거나 사용자 systemd 서비스 `earlgrey-notifications`로 dunst를 시작합니다.
공유 라이브러리가 부족하면 해당 항목을 보고하고 설치를 중단합니다.

현재 WSLg 환경에서 사용자가 한글 팝업과 소리를 모두 확인했습니다.
오디오 RDPSink 모니터에서도 실제 출력 파형을 확인했습니다.

## 검증

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests -p 'test_agent*.py'
EARLGREY_NOTIFY_HEADLESS=1 nvim --headless '+luafile tests/test_notifications.lua' '+qa!'
```

두 번째 검사는 외부 Python 프로세스 → inbox → 실제 nvim-notify 기록과
끄기 동작을 확인합니다. 실제 에이전트 실행이나 OS 팝업·소리의 수신 검증을
대신하지 않습니다. native Windows/macOS 동작은 별도 환경에서 확인해야 합니다.
