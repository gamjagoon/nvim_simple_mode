-- Platform-specific process launchers and terminal-sized UI settings.
local M = {}

function M.setup_windows_toolchain()
  if vim.fn.has('win32') ~= 1 then return false end
  local function driver(name)
    if vim.env.LLVM_MINGW_ROOT and vim.env.LLVM_MINGW_ROOT ~= '' then
      local path = vim.fs.joinpath(vim.env.LLVM_MINGW_ROOT, 'bin', name)
      local stat = vim.uv.fs_stat(path)
      return stat and stat.type == 'file' and path or ''
    end
    return vim.fn.exepath(name)
  end
  local cc = driver('x86_64-w64-mingw32-clang.exe')
  local cxx = driver('x86_64-w64-mingw32-clang++.exe')
  if cc == '' or cxx == '' then return false end
  vim.env.CC, vim.env.CXX = cc, cxx
  for _, target in ipairs({ 'x86_64-pc-windows-msvc', 'x86_64_pc_windows_msvc',
    'x86_64-pc-windows-gnullvm', 'x86_64_pc_windows_gnullvm' }) do
    vim.env['CC_' .. target], vim.env['CXX_' .. target] = cc, cxx
  end
  -- The MSVC-hosted tree-sitter CLI injects its own --target. cc-rs appends
  -- these flags last, allowing LLVM-MinGW to build parser DLLs without MSVC.
  for _, target in ipairs({ 'x86_64-pc-windows-msvc', 'x86_64_pc_windows_msvc' }) do
    for _, prefix in ipairs({ 'CFLAGS', 'CXXFLAGS' }) do
      local key = prefix .. '_' .. target
      local flags = vim.env[key]
      if not flags or flags == '' then flags = vim.env[prefix] or '' end
      if not flags:match('%-%-target=x86_64%-w64%-windows%-gnu%s*$') then
        flags = flags .. ' --target=x86_64-w64-windows-gnu'
      end
      vim.env[key] = vim.trim(flags)
    end
  end
  vim.env.RUSTUP_TOOLCHAIN = 'stable-x86_64-pc-windows-gnullvm'
  vim.env.CARGO_TARGET_X86_64_PC_WINDOWS_GNULLVM_LINKER = cc
  return true
end

function M.pyright_command()
  if vim.fn.has('win32') == 1 then
    -- npm installs a batch launcher; libuv cannot execute .cmd files directly.
    return { vim.env.COMSPEC or 'cmd.exe', '/d', '/c', 'pyright-langserver.cmd', '--stdio' }
  end
  return { 'pyright-langserver', '--stdio' }
end

function M.hex_options()
  if vim.fn.has('win32') == 1 then
    -- Legacy-encoded text is still text. Keep extension/-b binary detection.
    return { is_file_binary_post_read = function() return false end }
  end
  return {}
end

function M.tree_float_config()
  local width = math.max(1, math.min(100, vim.o.columns - 4))
  local height = math.max(1, math.min(50, vim.o.lines - vim.o.cmdheight - 4))
  return {
    relative = 'editor', border = 'rounded', width = width, height = height,
    row = math.max(0, math.floor((vim.o.lines - vim.o.cmdheight - height) / 2) - 1),
    col = math.max(0, math.floor((vim.o.columns - width) / 2)),
  }
end

return M
