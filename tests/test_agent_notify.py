import importlib.util
import io
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch, Mock

spec = importlib.util.spec_from_file_location('sender', Path(__file__).resolve().parents[1] / 'script/agent-notify.py')
sender = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sender)


class SenderTests(unittest.TestCase):
    def test_main_and_subagent_distinction(self):
        with patch.dict(os.environ, {}, clear=True):
            self.assertTrue(sender.main_session('claude', {'agent_type': 'custom-main'}))
            for payload in ({'agent_id': 'child'}, {'hook_event_name': 'SubagentStop'},
                            {'is_subagent': True}, {'agent_transcript_path': '/child/log'}):
                self.assertFalse(sender.main_session('claude', payload))

    def test_jcode_session_metadata(self):
        with tempfile.TemporaryDirectory() as root, patch.dict(os.environ, {'JCODE_HOME': root}, clear=True):
            folder = Path(root) / 'sessions'
            folder.mkdir()
            path = folder / 'main.json'
            payload = {'session_id': 'main'}
            self.assertFalse(sender.main_session('jcode', payload))
            for metadata, expected in [({'id': 'main', 'parent_id': None}, True),
                                       ({'id': 'main', 'parent_id': 'parent'}, False),
                                       ({'id': 'main', 'parent_id': None, 'is_debug': True}, False),
                                       ({'id': 'main'}, False)]:
                path.write_text(json.dumps(metadata))
                self.assertEqual(sender.main_session('jcode', payload), expected)
            self.assertFalse(sender.main_session('jcode', {'session_id': '../main'}))

    def test_subagent_has_no_side_effects(self):
        with tempfile.TemporaryDirectory() as root:
            folder = Path(root)/'nvim/agent-notifications'/f'{os.getpid()}-test'
            folder.mkdir(parents=True)
            env = dict(XDG_STATE_HOME=root)
            with patch.dict(os.environ, env, clear=True), patch.object(sys, 'argv', ['sender', '--agent', 'claude']), \
                 patch.object(sys, 'stdin', io.StringIO('{"agent_id":"child"}')), \
                 patch.object(sender, 'run') as run, patch.object(sender, 'wsl_popup') as popup:
                self.assertEqual(sender.main(), 0)
                self.assertEqual(list(folder.iterdir()), [])
                run.assert_not_called()
                popup.assert_not_called()

    def test_invalid_or_oversized_hook_never_rings(self):
        for text in ('{"agent_id":', '[]', '{"agent_id":"child","large":"' + 'x' * 1048576 + '"}'):
            with patch.dict(os.environ, {}, clear=True), patch.object(sys, 'argv', ['sender', '--agent', 'claude']), \
                 patch.object(sys, 'stdin', io.StringIO(text)), patch.object(sender, 'main_session') as classify, \
                 patch.object(sender, 'run') as run, patch.object(sender, 'wsl_popup') as popup:
                self.assertEqual(sender.main(), 0)
                classify.assert_not_called()
                run.assert_not_called()
                popup.assert_not_called()

    def test_question_reaches_inbox(self):
        with tempfile.TemporaryDirectory() as root:
            folder = Path(root)/'nvim/agent-notifications'/f'{os.getpid()}-test'
            folder.mkdir(parents=True)
            with patch.dict(os.environ, {'XDG_STATE_HOME': root}, clear=True), \
                 patch.object(sys, 'argv', ['sender', '--agent', 'claude', '--event', 'question', '--no-desktop', '--no-sound']), \
                 patch.object(sys, 'stdin', io.StringIO('{"session_id":"main"}')):
                self.assertEqual(sender.main(), 0)
            event = json.loads(next(folder.glob('*.json')).read_text())
            self.assertEqual(event['kind'], 'question')
            self.assertIn('입력', event['message'])

    def test_wayland_popup_uses_arguments_and_native_socket(self):
        process = Mock()
        process.wait.side_effect = subprocess.TimeoutExpired('zenity', .3)
        with patch.object(sender.subprocess, 'Popen', return_value=process) as spawn:
            self.assertTrue(sender.wsl_popup('한글 title', '$(touch /tmp/no)'))
        args, kwargs = spawn.call_args
        self.assertIn('--no-markup', args[0])
        self.assertIn('--text=$(touch /tmp/no)', args[0])
        self.assertEqual(kwargs['env']['GDK_BACKEND'], 'wayland')
        self.assertEqual(kwargs['env']['WAYLAND_DISPLAY'], '/mnt/wslg/runtime-dir/wayland-0')


if __name__ == '__main__':
    unittest.main()
