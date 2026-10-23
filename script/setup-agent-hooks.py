#!/usr/bin/env python3
"""Install optional completion hooks without replacing unrelated agent settings."""
import argparse
import datetime
import json
import os
from pathlib import Path
import re
import shlex
import shutil
import sys
import tempfile

MARKER = 'earlgrey-agent-notify'


def command(agent):
    return shlex.join([sys.executable, str(Path(__file__).resolve().with_name('agent-notify.py')), '--agent', agent])


def claude_config(text, remove=False):
    data = json.loads(text or '{}')
    hooks = data.setdefault('hooks', {})
    specs = [('Stop', None, 'complete'),
             ('Notification', 'permission_prompt|elicitation_dialog|elicitation_url_dialog|agent_needs_input', 'question'),
             ('PreToolUse', 'AskUserQuestion', 'question')]
    for event, matcher, notification in specs:
        groups = hooks.get(event, [])
        # Remove only owned command entries, preserving user-added peers in a group.
        cleaned = []
        for group in groups:
            entries = group.get('hooks', [])
            kept = [h for h in entries if not h.get('command', '').endswith(' # ' + MARKER)]
            if kept or not entries:
                cleaned.append(dict(group, hooks=kept))
        if not remove:
            group = {'hooks': [{'type': 'command', 'command': command('claude') +
                ' --event ' + notification + ' # ' + MARKER, 'timeout': 10}]}
            if matcher:
                group['matcher'] = matcher
            cleaned.append(group)
        if cleaned:
            hooks[event] = cleaned
        else:
            hooks.pop(event, None)
    return json.dumps(data, indent=2, ensure_ascii=False) + '\n'


def jcode_config(text, remove=False):
    try:
        import tomllib
    except ImportError:
        raise ValueError('jcode configuration requires Python 3.11+ (tomllib)')
    data = tomllib.loads(text)
    existing = data.get('hooks', {}).get('turn_end', [])
    if isinstance(existing, str):
        existing = [existing]
    if not isinstance(existing, list) or not all(isinstance(x, str) for x in existing):
        raise ValueError('hooks.turn_end must be a command string or string array')
    # Recognize only our command, including its previous repository location.
    def owned(value):
        try:
            args = shlex.split(value)
            return len(args) == 4 and Path(args[1]).name == 'agent-notify.py' and args[2:] == ['--agent', 'jcode']
        except ValueError:
            return False
    values = [x for x in existing if not owned(x)]
    if not remove:
        values.append(command('jcode'))
    replacement = 'turn_end = ' + json.dumps(values, ensure_ascii=False) + '\n'
    section = re.search(r'(?m)^\[hooks\][ \t]*(?:#[^\n]*)?\n?', text)
    if not section:
        if 'hooks' in data:
            raise ValueError('nonstandard hooks TOML layout; merge [hooks].turn_end manually')
        result = text.rstrip() + '\n\n[hooks]\n' + replacement
    else:
        start = section.end()
        following = re.search(r'(?m)^\s*\[', text[start:])
        end = start + following.start() if following else len(text)
        body = text[start:end]
        match = re.search(r'(?m)^turn_end\s*=', body)
        if match:
            # Parse progressively to support multi-line arrays and strings.
            tail = body[match.start():]
            consumed = 0
            for line in tail.splitlines(keepends=True):
                consumed += len(line)
                try:
                    parsed = tomllib.loads(tail[:consumed])
                except tomllib.TOMLDecodeError:
                    continue
                if 'turn_end' in parsed:
                    break
            body = body[:match.start()] + replacement + tail[consumed:]
        elif 'turn_end' in data.get('hooks', {}):
            raise ValueError('nonstandard turn_end spelling; merge manually')
        else:
            body = replacement + body
        result = text[:start] + body + text[end:]
    parsed = tomllib.loads(result)
    expected = dict(data)
    expected['hooks'] = dict(data.get('hooks', {}), turn_end=values)
    if parsed != expected:
        raise ValueError('TOML merge changed unrelated configuration; refusing')
    return result


def pi_extension(event):
    return '''// Managed by earlgrey-agent-notify. Re-run setup-agent-hooks.py to update.
import { spawn } from "node:child_process";
export default function (pi) {
  function notify(ctx, event) {
    // Core workers run without an interactive UI. Interactive custom workers
    // must set EARLGREY_NOTIFY_DISABLE=1 when launched.
    if (!ctx.hasUI || process.env.EARLGREY_NOTIFY_DISABLE === "1") return;
    const child = spawn(PYTHON, [SENDER, "--agent", "pi", "--event", event], {
      stdio: ["pipe", "ignore", "ignore"], detached: true,
    });
    const report = (error) => {
      if (ctx.hasUI) ctx.ui.notify("earlgrey notification failed: " + error, "warning");
      else console.error("earlgrey notification failed:", error);
    };
    child.on("error", report);
    child.stdin.on("error", report);
    child.on("exit", (code) => { if (code !== null && code !== 0) report("exit " + code); });
    child.stdin.end(JSON.stringify({cwd: ctx.cwd, session_id: ctx.sessionManager.getSessionId()}));
    child.unref();
  }
  pi.on(EVENT, async (_event, ctx) => { notify(ctx, "complete"); });
  pi.on("ui_prompt_start", async (_event, ctx) => { notify(ctx, "question"); });
}
'''.replace('EVENT', json.dumps(event)).replace('PYTHON', json.dumps(sys.executable)).replace('SENDER', json.dumps(str(Path(__file__).resolve().with_name('agent-notify.py'))))


def write_change(path, value, dry_run):
    old = path.read_text() if path.exists() else None
    if value == old:
        print(f'unchanged: {path}')
        return
    print(f'{"would update" if dry_run else "update"}: {path}')
    if dry_run:
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    if old is not None:
        suffix = datetime.datetime.now().strftime('%Y%m%d%H%M%S%f')
        backup = path.with_name(path.name + '.earlgrey-backup-' + suffix)
        shutil.copy2(path, backup)
        print(f'backup: {backup}')
    if value is None:
        path.unlink()
        return
    fd, temp = tempfile.mkstemp(dir=path.parent, prefix='.earlgrey-')
    try:
        with os.fdopen(fd, 'w') as stream:
            stream.write(value)
        if path.exists():
            os.chmod(temp, path.stat().st_mode & 0o777)
        os.replace(temp, path)
    finally:
        if os.path.exists(temp):
            os.unlink(temp)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--dry-run', action='store_true')
    parser.add_argument('--uninstall', action='store_true')
    parser.add_argument('--agent', choices=['all', 'claude', 'jcode', 'pi'], default='all')
    parser.add_argument('--pi-event', choices=['agent_settled', 'agent_end'], default='agent_settled', help='Use agent_end explicitly for older Pi versions; it may notify before retries finish')
    args = parser.parse_args()
    if os.name == 'nt':
        parser.error('Run this hook installer in Linux, WSL, or macOS; native Windows is unsupported')
    base = Path.home()
    paths = {
        'claude': Path(os.environ.get('CLAUDE_CONFIG_DIR', base / '.claude')) / 'settings.json',
        'jcode': Path(os.environ.get('JCODE_HOME', base / '.jcode')) / 'config.toml',
        'pi': Path(os.environ.get('PI_CODING_AGENT_DIR', base / '.pi/agent')) / 'extensions/earlgrey-agent-notify.js',
    }
    failures = 0
    for agent, path in paths.items():
        if args.agent not in ('all', agent):
            continue
        if not args.uninstall and not shutil.which(agent):
            print(f'skip: {agent} not installed on PATH')
            continue
        if args.uninstall and not path.exists():
            continue
        try:
            old = path.read_text() if path.exists() else ''
            if agent == 'pi':
                if old and not old.startswith('// Managed by ' + MARKER + '.'):
                    raise ValueError('existing Pi extension is not owned by this installer')
                value = None if args.uninstall else pi_extension(args.pi_event)
            else:
                value = (claude_config if agent == 'claude' else jcode_config)(old, args.uninstall)
            write_change(path, value, args.dry_run)
        except (OSError, ValueError, TypeError, AttributeError) as error:
            failures += 1
            print(f'error: {agent}: {error}', file=sys.stderr)
    return 1 if failures else 0


if __name__ == '__main__':
    sys.exit(main())
