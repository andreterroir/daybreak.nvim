local gdbus = require('daybreak.gdbus')
local macos = require('daybreak.macos')
local windows = require('daybreak.windows')

local M = {}
M.did_setup = false

local function has_desktop_session()
  if vim.fn.has('gui_running') == 1 then
    return true
  end
  local env = vim.env
  if env.WAYLAND_DISPLAY or env.DISPLAY or env.MIR_SOCKET then
    return true
  end
  -- SSH with X11 forwarding still sets DISPLAY. A forwarded session is a
  -- desktop for this purpose; a plain SSH login is not.
  return false
end

function M.setup(opts)
  if M.did_setup then
    return
  end
  M.did_setup = true
  if not has_desktop_session() then
    return
  end
  local sunrise = function()
    vim.opt.background = 'light'
    if opts and opts.light then
      vim.cmd('colorscheme ' .. opts.light)
    end
  end
  local sunset = function()
    vim.opt.background = 'dark'
    if opts and opts.dark then
      vim.cmd('colorscheme ' .. opts.dark)
    end
  end
  local helios
  if vim.fn.has('osx') == 1 then
    helios = macos.setup
  elseif vim.fn.has('win32') == 1 or vim.fn.has('win64') == 1 then
    helios = windows.setup
  elseif vim.fn.executable('gdbus') == 1 then
    helios = gdbus.setup
  end
  if helios then
    helios(sunrise, sunset)
  end
end

return M
