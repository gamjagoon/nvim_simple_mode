-- Platform-specific process launchers and terminal-sized UI settings.
local M = {}

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
