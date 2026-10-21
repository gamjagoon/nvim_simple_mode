-- Run after loading the configuration. Picker calls are intercepted to avoid a UI.
local function check()
  assert(vim.v.errmsg == '', 'startup error: ' .. vim.v.errmsg)
  local fzf = require('fzf-lua')
  local config = require('fzf-lua.config').globals
  assert(config.files.cmd:match('^fd%s'), 'file search must explicitly use fd')
  assert(config.grep.cmd:match('^rg%s'), 'content search must explicitly use rg')
  assert(config.grep.rg_glob, 'live grep must support file glob restrictions')

  local saved, calls = {}, {}
  for _, name in ipairs({ 'files', 'grep_cword', 'live_grep', 'blines' }) do
    saved[name] = fzf[name]
    fzf[name] = function(opts)
      calls[#calls + 1] = { name = name, opts = opts or {}, buf = vim.api.nvim_get_current_buf() }
    end
  end

  local original_cwd, original_buf = vim.fn.getcwd(), vim.api.nvim_get_current_buf()
  local root = vim.fn.tempname()
  local buffers = {}
  local ok, err = xpcall(function()
    for index, word in ipairs({ 'first_symbol', 'second_symbol' }) do
      local cwd = root .. '/project ' .. index
      vim.fn.mkdir(cwd, 'p')
      vim.api.nvim_set_current_dir(cwd)
      local buf = vim.api.nvim_create_buf(false, true)
      buffers[#buffers + 1] = buf
      vim.api.nvim_set_current_buf(buf)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { word .. ' unrelated' })
      vim.api.nvim_win_set_cursor(0, { 1, 0 })

      for lhs, expected in pairs({
        [' ff'] = 'files', [' fs'] = 'grep_cword', [' fg'] = 'live_grep',
        [' /'] = 'blines', [' rg'] = 'live_grep',
      }) do
        local mapping = vim.fn.maparg(lhs, 'n', false, true)
        assert(type(mapping.callback) == 'function', 'missing search callback: ' .. lhs)
        local before = #calls
        mapping.callback()
        assert(#calls == before + 1, 'search must invoke one picker: ' .. lhs)
        local call = calls[#calls]
        assert(call.name == expected, 'incorrect picker for ' .. lhs)
        assert(call.buf == buf, 'picker must use the active buffer')
        if lhs ~= ' /' then
          assert(call.opts.cwd == cwd, 'search must use the current working directory: ' .. lhs)
        end
        if lhs == ' rg' then
          assert(call.opts.search == word, 'live grep must start with the current cursor word')
        elseif lhs == ' fg' then
          assert(not call.opts.search or call.opts.search == '', 'project grep must start without a cursor word')
        end
      end
    end
  end, debug.traceback)

  for name, method in pairs(saved) do fzf[name] = method end
  vim.api.nvim_set_current_buf(original_buf)
  vim.api.nvim_set_current_dir(original_cwd)
  for _, buf in ipairs(buffers) do vim.api.nvim_buf_delete(buf, { force = true }) end
  vim.fn.delete(root, 'rf')
  assert(ok, err)
  print('PASS: search mappings, current project/buffer, cursor word and fd/rg configuration')
end

local ok, err = xpcall(check, debug.traceback)
if not ok then
  vim.api.nvim_err_writeln(err)
  vim.cmd('cquit 1')
end
