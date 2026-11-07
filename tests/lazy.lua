local root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h')
vim.opt.runtimepath:prepend(root)

local lazy = assert(vim.env.DAYBREAK_LAZY_PATH, 'Set DAYBREAK_LAZY_PATH to a lazy.nvim checkout')
local theme = assert(vim.env.DAYBREAK_THEME_PATH, 'Set DAYBREAK_THEME_PATH to a github-nvim-theme checkout')

-- Fake portal reporting a light appearance so the outcome is fixed.
local bin = vim.fn.tempname()
vim.fn.mkdir(bin, 'p')
if vim.fn.has('linux') == 1 then
  local gdbus = bin .. '/gdbus'
  vim.fn.writefile({
    '#!/bin/sh',
    'case "$*" in *monitor*) sleep 5 ;; *) printf "(<<uint32 2>>,)\\n" ;; esac',
  }, gdbus)
  vim.fn.setfperm(gdbus, 'rwxr-xr-x')
  vim.env.PATH = bin .. ':' .. vim.env.PATH
  vim.env.DISPLAY = ':1'
  vim.env.WAYLAND_DISPLAY = nil
end

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
vim.wait(2000, function() return vim.g.colors_name ~= nil end)
assert(vim.g.daybreak_did_setup == 1, 'Lazy opts must reach setup')
local expected = vim.o.background == 'light' and 'github_light' or 'github_dark_dimmed'
assert(vim.g.colors_name == expected,
  vim.inspect({ background = vim.o.background, colors_name = vim.g.colors_name }))
print('PASS lazy')
