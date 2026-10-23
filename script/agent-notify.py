#!/usr/bin/env python3
"""Deliver agent lifecycle notifications without executing payload text as code."""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import uuid


def run(command):
    try:
        return subprocess.run(command, timeout=4, stdout=subprocess.DEVNULL,
                              stderr=subprocess.DEVNULL).returncode == 0
    except (OSError, subprocess.TimeoutExpired):
        return False


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--agent', default='Agent')
    parser.add_argument('--message', default='응답이 끝났습니다.')
    parser.add_argument('--no-desktop', action='store_true')
    parser.add_argument('--no-sound', action='store_true')
    args = parser.parse_args()
    payload = {}
    if os.environ.get('JCODE_HOOK_PAYLOAD'):
        try:
            payload = json.loads(os.environ['JCODE_HOOK_PAYLOAD'])
        except ValueError:
            pass
    if not sys.stdin.isatty() and not os.environ.get('JCODE_HOOK_PAYLOAD'):
        try:
            payload = json.loads(sys.stdin.read(16385) or '{}')
        except (ValueError, OSError):
            pass
    if not isinstance(payload, dict):
        payload = {}
    event = dict(agent=args.agent[:80], message=args.message[:500],
                 cwd=str(payload.get('cwd') or os.environ.get('JCODE_HOOK_CWD') or os.getcwd())[:1000],
                 session_id=str(payload.get('session_id') or payload.get('sessionId') or os.environ.get('JCODE_HOOK_SESSION_ID') or '')[:100])
    app = os.environ.get('NVIM_APPNAME', 'nvim')
    state = Path(os.environ.get('XDG_STATE_HOME', str(Path.home() / '.local/state')))
    root = state / app / 'agent-notifications'
    delivered = 0
    for inbox in root.glob('*'):
        if not inbox.is_dir() or inbox.is_symlink():
            continue
        try:
            os.kill(int(inbox.name.split('-')[0]), 0)
            target = inbox / (uuid.uuid4().hex + '.json')
            temp = target.with_suffix('.tmp')
            with temp.open('x', encoding='utf-8') as stream:
                os.chmod(temp, 0o600)
                json.dump(event, stream, ensure_ascii=False)
            temp.replace(target)
            delivered += 1
        except (OSError, ValueError):
            continue
    title = args.agent[:80] + ' · ' + Path(event['cwd']).name
    desktop = False
    if not args.no_desktop:
        if shutil.which('notify-send'):
            desktop = run(['notify-send', '--app-name=earlgrey.nvim', '--expire-time=10000', '--', title, event['message']])
        elif sys.platform == 'darwin' and shutil.which('osascript'):
            # argv carries untrusted text; never interpolate it into AppleScript.
            desktop = run(['osascript', '-e', 'on run argv\ndisplay notification (item 2 of argv) with title (item 1 of argv)\nend run', title, event['message']])
    sound = False
    if not args.no_sound:
        if sys.platform == 'darwin' and shutil.which('afplay'):
            sound = run(['afplay', '/System/Library/Sounds/Glass.aiff'])
        elif shutil.which('canberra-gtk-play'):
            sound = run(['canberra-gtk-play', '-i', 'complete'])
        elif shutil.which('paplay'):
            for path in ['/usr/share/sounds/freedesktop/stereo/complete.oga', '/usr/share/sounds/freedesktop/stereo/bell.oga']:
                if Path(path).is_file():
                    sound = run(['paplay', path])
                    break
    print(f'earlgrey: inboxes={delivered} desktop={desktop} sound={sound}')
    # Missing optional backends must not interrupt the agent.
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
