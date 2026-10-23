-- External hooks drop JSON files here; no remote Lua execution is exposed.
local M = { enabled = true }
local uv = vim.uv
local inbox
local timer

function M.receive(event)
  if not M.enabled or type(event) ~= 'table' then return end
  local function clean(value, fallback)
    if type(value) ~= 'string' then return fallback end
    return value:gsub('[%c]', ' '):sub(1, 500)
  end
  local agent = clean(event.agent, 'Agent')
  local project = vim.fn.fnamemodify(clean(event.cwd, ''), ':t')
  local session = clean(event.session_id, ''):sub(1, 12)
  local title = agent .. (project ~= '' and ' · ' .. project or '')
  local message = clean(event.message, '응답이 끝났습니다.')
  if session ~= '' then message = message .. '\nSession: ' .. session end
  vim.notify(message, vim.log.levels.INFO, { title = title, timeout = 10000 })
end

function M.poll()
  if not inbox then return end
  local scan = uv.fs_scandir(inbox)
  if not scan then return end
  while true do
    local name, kind = uv.fs_scandir_next(scan)
    if not name then break end
    if kind == 'file' and name:match('%.json$') then
      local path = inbox .. '/' .. name
      local stat = uv.fs_stat(path)
      if stat and stat.size <= 16384 then
        local ok, event = pcall(function()
          return vim.json.decode(table.concat(vim.fn.readfile(path), '\n'))
        end)
        if ok then M.receive(event) end
      end
      uv.fs_unlink(path)
    end
  end
end

function M.setup()
  local group = vim.api.nvim_create_augroup('EarlgreyAgentNotifications', { clear = true })
  -- Headless tests do not need an inbox unless they explicitly request one.
  if #vim.api.nvim_list_uis() > 0 or vim.env.EARLGREY_NOTIFY_HEADLESS == '1' then
    local root = vim.fn.stdpath('state') .. '/agent-notifications'
    vim.fn.mkdir(root, 'p', 448)
    inbox = root .. '/' .. uv.os_getpid() .. '-' .. tostring(uv.hrtime())
    vim.fn.mkdir(inbox, 'p', 448)
    timer = uv.new_timer()
    timer:start(500, 500, vim.schedule_wrap(M.poll))
    vim.api.nvim_create_autocmd('VimLeavePre', { group = group, callback = function()
      timer:stop()
      timer:close()
      vim.fn.delete(inbox, 'rf')
    end })
  end
  vim.api.nvim_create_user_command('AgentNotifications', function(opts)
    if opts.args == 'test' then
      M.receive({ agent = 'Test', cwd = vim.fn.getcwd(), message = '알림 연결 테스트' })
    elseif opts.args == 'on' or opts.args == 'off' then
      M.enabled = opts.args == 'on'
      vim.notify('Agent notifications: ' .. opts.args)
    else
      vim.notify('Agent notifications: ' .. (M.enabled and 'on' or 'off') .. '\nInbox: ' .. (inbox or 'headless (disabled)'))
    end
  end, { nargs = '?', complete = function() return { 'on', 'off', 'test', 'status' } end })
  vim.keymap.set('n', '<leader>nh', '<cmd>Notifications<cr>', { desc = 'Notification history' })
  vim.keymap.set('n', '<leader>nd', function() require('notify').dismiss({ silent = true, pending = true }) end,
    { desc = 'Dismiss notifications' })
end

return M
