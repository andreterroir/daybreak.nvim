local root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h')
vim.opt.runtimepath:prepend(root)

local function equal(expected, actual)
  assert(vim.deep_equal(expected, actual), vim.inspect({ expected = expected, actual = actual }))
end

local function platform(name, display)
  vim.env.DISPLAY = display
  vim.env.WAYLAND_DISPLAY = nil
  vim.env.MIR_SOCKET = nil
  local has = vim.fn.has
  vim.fn.has = function(feature)
    if feature == 'osx' then return name == 'macos' and 1 or 0 end
    if feature == 'gui_running' or feature == 'win32' or feature == 'win64' then return 0 end
    return has(feature)
  end
end

local function macos()
  platform('macos')
  os.execute = function() return 0 end
  local callbacks = {}
  local executable = vim.fn.executable
  vim.fn.executable = function(path)
    if path:match('/appearance$') then return 1 end
    return executable(path)
  end
  vim.fn.jobstart = function(path, opts)
    assert(path:match('/appearance$'), path)
    callbacks[#callbacks + 1] = opts.on_stdout
    return #callbacks
  end
  return callbacks
end

local tests = {}

function tests.lazy_configured()
  local callbacks = macos()
  local lazy = assert(vim.env.DAYBREAK_LAZY_PATH, 'Set DAYBREAK_LAZY_PATH to a lazy.nvim checkout')
  local theme = assert(vim.env.DAYBREAK_THEME_PATH, 'Set DAYBREAK_THEME_PATH to a github-nvim-theme checkout')
  vim.opt.runtimepath:prepend(lazy)
  vim.opt.loadplugins = true
  require('lazy').setup({
    { dir = theme, name = 'github-nvim-theme', lazy = false },
    {
      dir = root,
      name = 'daybreak.nvim',
      lazy = false,
      dependencies = { 'github-nvim-theme' },
      opts = { light = 'github_light', dark = 'github_dark_dimmed' },
    },
  }, {
    root = vim.fn.tempname(),
    lockfile = vim.fn.tempname(),
    install = { missing = false },
    checker = { enabled = false },
    change_detection = { enabled = false },
    readme = { enabled = false },
  })
  assert(vim.fn.execute('scriptnames'):find('/plugin/daybreak.lua', 1, true),
    'Lazy must source plugin/daybreak.lua')
  vim.wait(20)
  equal(1, #callbacks)
  equal('github_dark_dimmed', vim.g.colors_name)
  callbacks[1](1, { 'light', '' })
  equal('github_light', vim.g.colors_name)
  callbacks[1](1, { 'da' })
  equal('github_light', vim.g.colors_name)
  callbacks[1](1, { 'rk', '' })
  equal('github_dark_dimmed', vim.g.colors_name)
  callbacks[1](1, { 'li' })
  equal('github_dark_dimmed', vim.g.colors_name)
  callbacks[1](1, { 'ght', '' })
  equal('light', vim.o.background)
  equal('github_light', vim.g.colors_name)
  callbacks[1](1, { 'dark', 'light', 'dark', '' })
  equal('dark', vim.o.background)
  equal('github_dark_dimmed', vim.g.colors_name)
end

function tests.automatic_setup()
  local callbacks = macos()
  vim.cmd('runtime plugin/daybreak.lua')
  vim.wait(20)
  equal(1, #callbacks)
  equal('dark', vim.o.background)
  callbacks[1](1, { 'light', '' })
  equal('light', vim.o.background)
end

function tests.explicit_setup()
  local callbacks = macos()
  require('daybreak').setup()
  vim.cmd('runtime plugin/daybreak.lua')
  require('daybreak').setup()
  vim.wait(20)
  equal(1, #callbacks)
end

function tests.fragmented_notifications()
  local callbacks = macos()
  local seen = {}
  require('daybreak.macos').setup(function() seen[#seen + 1] = 'light' end,
    function() seen[#seen + 1] = 'dark' end)
  seen = {}
  callbacks[1](1, { 'l' })
  callbacks[1](1, { 'i' })
  equal({}, seen)
  callbacks[1](1, { 'ght', 'dark', 'li' })
  equal({ 'light', 'dark' }, seen)
  callbacks[1](1, { 'ght', '', 'unexpected', '' })
  equal({ 'light', 'dark', 'light' }, seen)
  callbacks[1](1, { 'da' })
  callbacks[1](1, { '' })
  equal({ 'light', 'dark', 'light' }, seen)
end

function tests.independent_watchers()
  local callbacks = macos()
  local seen = {}
  local backend = require('daybreak.macos')
  backend.setup(function() seen[#seen + 1] = 'first light' end, function() end)
  backend.setup(function() seen[#seen + 1] = 'second light' end, function() end)
  callbacks[1](1, { 'li' })
  callbacks[2](2, { 'dark', '' })
  callbacks[1](1, { 'ght', '' })
  equal({ 'first light' }, seen)
end

function tests.linux_headless()
  platform('linux')
  vim.fn.executable = function() error('headless setup must not probe executables') end
  io.popen = function() error('headless setup must not probe the portal') end
  vim.fn.jobstart = function() error('headless setup must not start a watcher') end
  local hour = tonumber(assert(vim.env.DAYBREAK_TEST_HOUR))
  os.date = function(format) equal('%H', format); return tostring(hour) end
  require('daybreak').setup({ light = 'default', dark = 'default' })
  local expected = { [0] = 'dark', [5] = 'dark', [6] = 'light',
    [18] = 'light', [19] = 'dark', [23] = 'dark' }
  equal(expected[hour], vim.o.background)
  equal('default', vim.g.colors_name)
end

function tests.linux_desktop()
  platform('linux', ':1')
  vim.fn.executable = function(command) equal('gdbus', command); return 1 end
  local calls = 0
  package.loaded['daybreak.gdbus'] = { setup = function(sunrise, sunset)
    calls = calls + 1
    sunset()
    equal('dark', vim.o.background)
    sunrise()
  end }
  require('daybreak').setup()
  equal(1, calls)
  equal('light', vim.o.background)
end

local name = arg[1]
if name then
  tests[name]()
  print('PASS ' .. name)
else
  local cases = { 'lazy_configured', 'automatic_setup', 'explicit_setup',
    'fragmented_notifications', 'independent_watchers', 'linux_desktop' }
  for _, hour in ipairs({ 0, 5, 6, 18, 19, 23 }) do
    cases[#cases + 1] = 'linux_headless:' .. hour
  end
  local failures = 0
  for _, case in ipairs(cases) do
    local test, hour = case:match('([^:]+):?(.*)')
    local result = vim.system({ vim.v.progpath, '--headless', '-u', 'NONE', '-i', 'NONE',
      '-l', root .. '/tests/regression.lua', test }, {
      env = { DAYBREAK_TEST_HOUR = hour },
    }):wait()
    io.stdout:write(result.stdout, result.stderr)
    if result.code ~= 0 then failures = failures + 1 end
  end
  assert(failures == 0, failures .. ' regression case(s) failed')
  print('PASS all ' .. #cases .. ' regression cases')
end
