-- Run with the normal configuration. Windows branches are synthetic on Unix.
local function check()
  local compat = require('compat')
  local saved_has, saved_comspec = vim.fn.has, vim.env.COMSPEC
  local ok, err = xpcall(function()
    vim.fn.has = function(feature)
      if feature == 'win32' then return 1 end
      return saved_has(feature)
    end
    vim.env.COMSPEC = 'C:\\Windows with spaces\\System32\\cmd.exe'
    local cmd = compat.pyright_command()
    assert(vim.deep_equal(cmd, { vim.env.COMSPEC, '/d', '/c', 'pyright-langserver.cmd', '--stdio' }),
      'Windows Pyright must launch the batch file via cmd with separate arguments')
    local options = compat.hex_options()
    vim.bo.fileencoding = 'latin1'
    assert(not options.is_file_binary_post_read(), 'legacy text must not become hex')
    vim.bo.fileencoding = 'utf-8'
    assert(not options.is_file_binary_post_read(), 'UTF-8 text must not become hex')
    vim.fn.has = function(feature)
      if feature == 'win32' then return 0 end
      return saved_has(feature)
    end
    assert(vim.deep_equal(compat.pyright_command(), { 'pyright-langserver', '--stdio' }))
    assert(next(compat.hex_options()) == nil, 'Unix hex configuration changed')
  end, debug.traceback)
  vim.fn.has, vim.env.COMSPEC = saved_has, saved_comspec
  vim.bo.fileencoding = ''
  assert(ok, err)

  -- Exercise a real popup in an 80x24 editor; old 100x50 dimensions overflowed.
  local columns, lines = vim.o.columns, vim.o.lines
  vim.o.columns, vim.o.lines = 80, 24
  local api = require('nvim-tree.api')
  local tree_ok, tree_err = xpcall(function()
    api.tree.open()
    local found = false
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].filetype == 'NvimTree' then
        local config = vim.api.nvim_win_get_config(win)
        assert(config.relative == 'editor')
        assert(config.width + 2 <= vim.o.columns and config.height + 2 < vim.o.lines)
        assert(config.row >= 0 and config.col >= 0)
        found = true
      end
    end
    assert(found, 'file tree popup did not open')
  end, debug.traceback)
  api.tree.close()
  vim.o.columns, vim.o.lines = columns, lines
  assert(tree_ok, tree_err)
  print('PASS: simulated Windows launch/encoding guards, Unix preservation, real small-terminal file tree')
end
local ok, err = xpcall(check, debug.traceback)
if not ok then
  vim.api.nvim_err_writeln(err)
  vim.cmd('cquit 1')
end
