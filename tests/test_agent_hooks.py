import importlib.util
from pathlib import Path
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('hooks', Path(__file__).resolve().parents[1] / 'script/setup-agent-hooks.py')
hooks = importlib.util.module_from_spec(spec)
spec.loader.exec_module(hooks)


class HookTests(unittest.TestCase):
    def test_claude_preserves_and_idempotent(self):
        import json
        source = '{"theme":"dark","hooks":{"Stop":[{"hooks":[{"type":"command","command":"other"}]}]}}'
        result = hooks.claude_config(source)
        self.assertEqual(result, hooks.claude_config(result))
        self.assertEqual(json.loads(hooks.claude_config(result, True)), json.loads(source))

    def test_jcode_multiline_and_preservation(self):
        import tomllib
        source = '# keep comment\nmodel = "x"\n[hooks]\nturn_end = [\n "first",\n "second"\n]\nturn_start = "busy"\n[other]\nfoo = 42\n'
        result = hooks.jcode_config(source)
        self.assertEqual(result, hooks.jcode_config(result))
        self.assertEqual(tomllib.loads(hooks.jcode_config(result, True)), tomllib.loads(source))
        self.assertIn('# keep comment', result)

    def test_jcode_single_command(self):
        import tomllib
        result = hooks.jcode_config('[hooks]\nturn_end = "other"\n')
        self.assertEqual(tomllib.loads(result)['hooks']['turn_end'][0], 'other')

    def test_jcode_rejects_unusual_layout(self):
        with self.assertRaises(ValueError):
            hooks.jcode_config('hooks = {turn_end = "other"}\n')

    def test_backup_and_dry_run(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'settings.json'
            path.write_text('old')
            hooks.write_change(path, 'new', True)
            self.assertEqual(path.read_text(), 'old')
            hooks.write_change(path, 'new', False)
            self.assertEqual(path.read_text(), 'new')
            self.assertEqual(next(Path(folder).glob('*.earlgrey-backup-*')).read_text(), 'old')
            hooks.write_change(path, 'new', False)
            self.assertEqual(len(list(Path(folder).glob('*.earlgrey-backup-*'))), 1)

    def test_cli_install_repeat_remove(self):
        import os
        import subprocess
        import sys
        with tempfile.TemporaryDirectory() as folder:
            base = Path(folder)
            bin_dir = base / 'bin'
            bin_dir.mkdir()
            for name in ('claude', 'jcode', 'pi'):
                executable = bin_dir / name
                executable.write_text('#!/bin/sh\nexit 0\n')
                executable.chmod(0o755)
            env = dict(os.environ, HOME=folder, PATH=str(bin_dir))
            env.pop('CLAUDE_CONFIG_DIR', None)
            env.pop('PI_CODING_AGENT_DIR', None)
            cmd = [sys.executable, str(Path(hooks.__file__))]
            subprocess.run(cmd + ['--dry-run'], env=env, check=True, capture_output=True)
            self.assertFalse((base / '.claude').exists())
            subprocess.run(cmd, env=env, check=True, capture_output=True)
            subprocess.run(cmd, env=env, check=True, capture_output=True)
            self.assertFalse(list(base.rglob('*.earlgrey-backup-*')))
            subprocess.run(cmd + ['--uninstall'], env=env, check=True, capture_output=True)
            self.assertFalse((base / '.pi/agent/extensions/earlgrey-agent-notify.js').exists())

    def test_pi_event_choice(self):
        self.assertIn('pi.on("agent_settled"', hooks.pi_extension('agent_settled'))
        self.assertIn('pi.on("agent_end"', hooks.pi_extension('agent_end'))
        self.assertIn('child.stdin.on("error", report)', hooks.pi_extension('agent_end'))


if __name__ == '__main__':
    unittest.main()
