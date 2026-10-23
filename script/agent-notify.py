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


def wsl_popup(title, message):
    """Use a normal Wayland window: WSLg does not reliably show tray banners."""
    env = dict(os.environ, GDK_BACKEND='wayland',
               WAYLAND_DISPLAY='/mnt/wslg/runtime-dir/wayland-0')
    try:
        process = subprocess.Popen(['zenity', '--info', '--no-markup',
                                    '--title=' + title, '--text=' + message,
                                    '--timeout=15', '--width=420'], env=env,
                                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                                   start_new_session=True)
        try:
            return process.wait(timeout=0.3) == 0
        except subprocess.TimeoutExpired:
            return True  # Window launched; this does not prove the user saw it.
    except OSError:
        return False


def main_session(agent, payload):
    """Suppress child agents before any popup, sound, or inbox write."""
    if os.environ.get('EARLGREY_NOTIFY_DISABLE') == '1':
        return False
    if payload.get('is_subagent') or payload.get('agent_id') or payload.get('agent_transcript_path'):
        return False
    if payload.get('hook_event_name') in ('SubagentStart', 'SubagentStop', 'TaskCompleted'):
        return False
    if agent == 'jcode':
        session_id = payload.get('session_id') or os.environ.get('JCODE_HOOK_SESSION_ID', '')
        if not isinstance(session_id, str) or not session_id or Path(session_id).name != session_id:
            return False
        directory = Path(os.environ.get('JCODE_HOME', str(Path.home() / '.jcode')))
        try:
            with (directory / 'sessions' / (session_id + '.json')).open() as stream:
                session = json.load(stream)
            return (isinstance(session, dict) and session.get('id') == session_id
                    and 'parent_id' in session and session['parent_id'] is None
                    and not session.get('is_debug', False))
        except (OSError, ValueError):
            return False  # Never ring for a session whose role is unknown.
    return True


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--agent', default='Agent')
    parser.add_argument('--message')
    parser.add_argument('--event', choices=['complete', 'question'], default='complete')
    parser.add_argument('--no-desktop', action='store_true')
    parser.add_argument('--no-sound', action='store_true')
    args = parser.parse_args()
    payload = {}
    if os.environ.get('JCODE_HOOK_PAYLOAD'):
        try:
            payload = json.loads(os.environ['JCODE_HOOK_PAYLOAD'])
        except ValueError:
            print("earlgrey: suppressed invalid hook payload")
            return 0
    if not sys.stdin.isatty() and not os.environ.get('JCODE_HOOK_PAYLOAD'):
        try:
            raw = sys.stdin.read(1048577)
            if len(raw) > 1048576:
                print('earlgrey: suppressed oversized hook payload')
                return 0
            payload = json.loads(raw or '{}')
        except (ValueError, OSError):
            print("earlgrey: suppressed invalid hook payload")
            return 0
    if not isinstance(payload, dict):
        print("earlgrey: suppressed non-object hook payload")
        return 0
    if not main_session(args.agent, payload):
        print('earlgrey: suppressed subagent or unverified session')
        return 0
    message = args.message or ('질문 또는 입력을 기다리고 있습니다.' if args.event == 'question' else '응답이 끝났습니다.')
    event = dict(agent=args.agent[:80], message=message[:500], kind=args.event,
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
    title = args.agent[:80] + (' · 입력 필요' if args.event == 'question' else ' · 응답 완료') + ' · ' + Path(event['cwd']).name
    desktop = False
    if not args.no_desktop:
        if Path('/mnt/wslg/runtime-dir/wayland-0').exists() and shutil.which('zenity'):
            desktop = wsl_popup(title, event['message'])
        elif shutil.which('notify-send'):
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
            sound_roots = [Path('/usr/share/sounds'),
                           Path.home() / '.local/opt/earlgrey-notify/root/usr/share/sounds']
            paths = [root / 'freedesktop/stereo' / name
                     for root in sound_roots for name in ('complete.oga', 'bell.oga')]
            for path in paths:
                if Path(path).is_file():
                    sound = run(['paplay', str(path)])
                    break
    print(f'earlgrey: inboxes={delivered} desktop={desktop} sound={sound}')
    # Missing optional backends must not interrupt the agent.
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
