-- Run with the normal configuration. Windows branches are synthetic on Unix.
local function check()
  local compat = require('compat')
  local saved_has, saved_comspec = vim.fn.has, vim.env.COMSPEC
  local saved_exepath = vim.fn.exepath
  local saved_env = {}
  local env_names = { 'CC', 'CXX', 'RUSTUP_TOOLCHAIN', 'LLVM_MINGW_ROOT', 'CFLAGS', 'CXXFLAGS',
    'CARGO_TARGET_X86_64_PC_WINDOWS_GNULLVM_LINKER' }
  for _, target in ipairs({ 'x86_64-pc-windows-msvc', 'x86_64_pc_windows_msvc',
    'x86_64-pc-windows-gnullvm', 'x86_64_pc_windows_gnullvm' }) do
    for _, prefix in ipairs({ 'CC_', 'CXX_', 'CFLAGS_', 'CXXFLAGS_' }) do
      env_names[#env_names + 1] = prefix .. target
    end
  end
  for _, name in ipairs(env_names) do saved_env[name] = vim.env[name] or false end
  local ok, err = xpcall(function()
    vim.fn.has = function(feature)
      if feature == 'win32' then return 1 end
      return saved_has(feature)
    end
    vim.env.COMSPEC = 'C:\\Windows with spaces\\System32\\cmd.exe'
    local cmd = compat.pyright_command()
    assert(vim.deep_equal(cmd, { vim.env.COMSPEC, '/d', '/c', 'pyright-langserver.cmd', '--stdio' }),
      'Windows Pyright must launch the batch file via cmd with separate arguments')
    vim.env.LLVM_MINGW_ROOT = nil
    vim.fn.exepath = function(name)
      if name:match('^x86_64%-w64%-mingw32%-clang') then return 'C:/LLVM MinGW/bin/' .. name end
      return saved_exepath(name)
    end
    vim.env.CFLAGS = '-O2'
    for _, key in ipairs({ 'CFLAGS_x86_64-pc-windows-msvc', 'CFLAGS_x86_64_pc_windows_msvc' }) do vim.env[key] = nil end
    assert(compat.setup_windows_toolchain(), 'Windows compiler selection failed')
    assert(vim.env.CC == 'C:/LLVM MinGW/bin/x86_64-w64-mingw32-clang.exe')
    assert(vim.env.RUSTUP_TOOLCHAIN == 'stable-x86_64-pc-windows-gnullvm')
    assert(vim.env.CARGO_TARGET_X86_64_PC_WINDOWS_GNULLVM_LINKER == vim.env.CC)
    local flags = vim.env['CFLAGS_x86_64-pc-windows-msvc']
    assert(flags == '-O2 --target=x86_64-w64-windows-gnu', 'Tree-sitter GNU override must be last')
    assert(compat.setup_windows_toolchain())
    assert(vim.env['CFLAGS_x86_64-pc-windows-msvc'] == flags, 'reinitialization duplicated flags')
    vim.fn.exepath = function() return '' end
    local previous = vim.env.CC
    assert(not compat.setup_windows_toolchain() and vim.env.CC == previous, 'missing drivers mutated compiler selection')
    vim.fn.exepath = saved_exepath
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
    local previous = vim.env.CC
    assert(not compat.setup_windows_toolchain() and vim.env.CC == previous, 'Unix compiler environment changed')
  end, debug.traceback)
  vim.fn.has, vim.env.COMSPEC, vim.fn.exepath = saved_has, saved_comspec, saved_exepath
  for name, value in pairs(saved_env) do
    if value == false then vim.env[name] = nil else vim.env[name] = value end
  end
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
