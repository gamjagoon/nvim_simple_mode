local function check()
  local notify = require('notify')
  local bridge = require('agent_notifications')
  local before = #notify.history()
  local result = vim.system({ 'python3', 'script/agent-notify.py', '--agent', 'Test Claude',
    '--message', 'done "quotes" $(touch /tmp/earlgrey-should-not-exist)', '--no-desktop', '--no-sound' },
    { stdin = vim.json.encode({ cwd = '/tmp/project', session_id = 'test-session' }), text = true }):wait()
  assert(result.code == 0, result.stderr)
  assert(result.stdout:find('inboxes=1', 1, true), result.stdout)
  assert(vim.wait(3000, function() return #notify.history() > before end, 20), 'no notification delivered')
  assert(vim.wait(1000, function()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_config(win).relative ~= '' then return true end
    end
    return false
  end, 20), 'notification floating window was not created')
  local history = notify.history()
  local event = history[#history]
  assert(table.concat(event.message, '\n'):find('test-session', 1, true))
  assert(event.title[1]:find('Test Claude', 1, true))
  vim.cmd('AgentNotifications off')
  local muted = #notify.history()
  bridge.receive({ agent = 'Muted' })
  assert(#notify.history() == muted, 'mute failed')
  vim.cmd('AgentNotifications on')
  bridge.receive('malformed')
  assert(vim.fn.filereadable('/tmp/earlgrey-should-not-exist') == 0)
  notify.dismiss({ silent = true, pending = true })
  print('PASS: external sender → inbox → nvim-notify history, payload quoting, mute')
end
local ok, err = xpcall(check, debug.traceback)
if not ok then
  vim.api.nvim_err_writeln(err)
  vim.cmd('cquit 1')
end
