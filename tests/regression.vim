" Runs one case under Vim or Neovim; tests/run.sh starts a fresh editor per case.
let s:root = expand('<sfile>:p:h:h')
execute 'set runtimepath^=' . fnameescape(s:root)
let $DISPLAY = ''
let $WAYLAND_DISPLAY = ''
let $MIR_SOCKET = ''

function! s:temp_dir() abort
  let dir = tempname()
  call mkdir(dir, 'p')
  return dir
endfunction

function! s:write_script(dir, name, lines) abort
  let path = a:dir . '/' . a:name
  call writefile(a:lines, path)
  call setfperm(path, 'rwxr-xr-x')
  return path
endfunction

function! s:wait_tick() abort
  if has('nvim')
    call luaeval('vim.wait(20)')
  else
    sleep 20m
  endif
endfunction

function! s:wait_for(expr) abort
  let start = reltime()
  while !eval(a:expr) && reltimefloat(reltime(start)) < 3.0
    call s:wait_tick()
  endwhile
endfunction

function! s:pause(ms) abort
  let start = reltime()
  while reltimefloat(reltime(start)) < a:ms / 1000.0
    call s:wait_tick()
  endwhile
endfunction

function! s:assert_applied(background, theme) abort
  call assert_equal(a:background, &background)
  call assert_equal(a:theme, g:colors_name)
endfunction

function! s:clock() abort
  let hour = str2nr($DAYBREAK_TEST_HOUR)
  let expected = hour >= 19 || hour < 6 ? 'dark' : 'light'
  call assert_equal(expected, daybreak#clock#background(hour))
endfunction

function! s:linux_headless() abort
  call daybreak#setup({'light': 'default', 'dark': 'desert'})
  if daybreak#clock#background() ==# 'dark'
    call s:assert_applied('dark', 'desert')
  else
    call s:assert_applied('light', 'default')
  endif
endfunction

function! s:automatic_setup() abort
  let g:daybreak_light = 'default'
  let g:daybreak_dark = 'desert'
  runtime! plugin/daybreak.vim
  call assert_equal(1, get(g:, 'daybreak_did_setup', 0))
  call assert_equal(&background ==# 'light' ? 'default' : 'desert', g:colors_name)
endfunction

function! s:explicit_setup() abort
  call daybreak#setup({'light': 'default', 'dark': 'desert'})
  call assert_equal(1, g:daybreak_did_setup)
  let theme = &background ==# 'light' ? 'default' : 'desert'
  call assert_equal(theme, g:colors_name)
  call daybreak#setup({'light': 'blue', 'dark': 'morning'})
  call assert_equal(theme, g:colors_name)
endfunction

function! s:linux_desktop() abort
  let prefix = "/org/freedesktop/portal/desktop: org.freedesktop.portal.Settings.SettingChanged ('org.freedesktop.appearance', 'color-scheme', <uint32 "
  let bin = s:temp_dir()
  call s:write_script(bin, 'gdbus', [
        \ '#!/bin/sh',
        \ 'case "$*" in',
        \ '  *monitor*)',
        \ '    sleep 0.2',
        \ '    printf "' . prefix . '"',
        \ '    sleep 0.2',
        \ '    printf "1)\n"',
        \ '    sleep 0.4',
        \ '    printf "/org/freedesktop/portal/desktop: org.freedesktop.portal.Settings.SettingChanged (''org.freedesktop.appearance'', ''accent-color'', <uint32 0)\n"',
        \ '    sleep 0.4',
        \ '    printf "' . prefix . '1)\n' . prefix . '2)\n"',
        \ '    sleep 5',
        \ '    ;;',
        \ '  *) printf "(<<uint32 2>>,)\n" ;;',
        \ 'esac',
        \ ])
  let $PATH = bin . ':' . $PATH
  let $DISPLAY = ':1'
  call daybreak#setup({'light': 'default', 'dark': 'desert'})
  call s:assert_applied('light', 'default')
  call s:wait_for('&background ==# "dark"')
  call s:assert_applied('dark', 'desert')
  call s:pause(600)
  call s:assert_applied('dark', 'desert')
  call s:wait_for('&background ==# "light"')
  call s:assert_applied('light', 'default')
endfunction

function! s:macos() abort
  " Copy the plugin so the appearance watcher path resolves inside the copy.
  let root = s:temp_dir()
  call system('cp -r ' . shellescape(s:root . '/autoload') . ' ' . shellescape(root . '/autoload'))
  call s:write_script(root, 'appearance', ['#!/bin/sh', 'sleep 0.2', 'echo light', 'sleep 5'])
  let bin = s:temp_dir()
  call s:write_script(bin, 'defaults', ['#!/bin/sh', 'echo Dark', 'exit 0'])
  let $PATH = bin . ':/usr/bin:/bin'
  execute 'set runtimepath^=' . fnameescape(root)
  call daybreak#macos#setup(
        \ function('daybreak#apply', ['light', 'default']),
        \ function('daybreak#apply', ['dark', 'desert']))
  call s:assert_applied('dark', 'desert')
  call s:wait_for('g:colors_name ==# "default"')
  call s:assert_applied('light', 'default')
endfunction

function! s:gdbus_read() abort
  let value = $DAYBREAK_TEST_SCHEME
  let bin = s:temp_dir()
  call s:write_script(bin, 'gdbus', ['#!/bin/sh',
        \ 'case "$*" in *monitor*) sleep 5 ;; *) printf "(<<uint32 ' . value . '>>,)\n" ;; esac'])
  let $PATH = bin . ':/usr/bin:/bin'
  call daybreak#gdbus#setup(
        \ function('daybreak#apply', ['light', 'default']),
        \ function('daybreak#apply', ['dark', 'desert']))
  call assert_equal(value ==# '1' ? 'desert' : 'default', g:colors_name)
endfunction

function! s:windows_dark() abort
  call s:windows('0', 'desert')
endfunction

function! s:windows_light() abort
  call s:windows('1', 'default')
endfunction

function! s:fake_reg(value) abort
  let bin = s:temp_dir()
  call s:write_script(bin, 'reg', ['#!/bin/sh',
        \ 'echo "    AppsUseLightTheme    REG_DWORD    0x' . a:value . '"'])
  let $PATH = bin . ':/usr/bin:/bin'
endfunction

function! s:windows(value, theme) abort
  call s:fake_reg(a:value)
  call daybreak#windows#setup(
        \ function('daybreak#apply', ['light', 'default']),
        \ function('daybreak#apply', ['dark', 'desert']))
  call assert_equal(a:theme, g:colors_name)
endfunction

function! s:windows_console() abort
  " Simulate a Windows console: no display variables or GUI, so setup must
  " read the registry before falling back to the clock.
  let root = s:temp_dir()
  call system('cp -r ' . shellescape(s:root . '/autoload') . ' '
        \ . shellescape(root . '/autoload'))
  let path = root . '/autoload/daybreak.vim'
  let lines = readfile(path)
  for [pattern, replacement] in [
        \ ["has('osx') || has('mac') || has('macunix')", '0'],
        \ ["has('win32') || has('win64')", '1'],
        \ ]
    let i = match(lines, pattern)
    call assert_true(i >= 0, 'missing platform check: ' . pattern)
    let lines[i] = substitute(lines[i], pattern, replacement, '')
  endfor
  call writefile(lines, path)
  execute 'set runtimepath^=' . fnameescape(root)
  call s:fake_reg('1')
  call daybreak#setup({'light': 'default', 'dark': 'desert'})
  call assert_equal('default', g:colors_name)
endfunction

let s:case = $DAYBREAK_TEST_CASE
try
  call call('s:' . s:case, [])
catch
  call add(v:errors, v:exception . ' (' . v:throwpoint . ')')
endtry
if empty(v:errors)
  echo 'PASS ' . s:case
  qa!
endif
for s:error in v:errors
  echomsg s:error
endfor
cquit 1
