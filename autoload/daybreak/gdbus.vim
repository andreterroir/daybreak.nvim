let s:prefix = "/org/freedesktop/portal/desktop:"
      \ . " org.freedesktop.portal.Settings.SettingChanged"
      \ . " ('org.freedesktop.appearance', 'color-scheme', <uint32 "

function! daybreak#gdbus#setup(Light, Dark) abort
  let output = system('gdbus call --session'
        \ . ' --dest=org.freedesktop.portal.Desktop'
        \ . ' --object-path=/org/freedesktop/portal/desktop'
        \ . ' --method=org.freedesktop.portal.Settings.Read'
        \ . ' org.freedesktop.appearance color-scheme')
  if v:shell_error != 0
    echomsg 'gdbus command failed'
  else
    call s:apply(output, a:Light, a:Dark)
  endif

  call daybreak#job#start([exepath('gdbus'), 'monitor', '--session',
        \ '--dest', 'org.freedesktop.portal.Desktop',
        \ '--object-path', '/org/freedesktop/portal/desktop'], {
        \ 'on_line': function('s:line', [a:Light, a:Dark]),
        \ 'on_exit': function('s:monitor_died'),
        \ })
endfunction

function! s:line(Light, Dark, line) abort
  if stridx(a:line, s:prefix) == 0
    call s:apply(a:line, a:Light, a:Dark)
  endif
endfunction

function! s:apply(output, Light, Dark) abort
  let match = matchlist(a:output, '<uint32 \(\d\)')
  if empty(match)
    return
  endif
  " 0 is no preference, 1 prefers dark, 2 prefers light.
  if match[1] ==# '1'
    call a:Dark()
  else
    call a:Light()
  endif
endfunction

function! s:monitor_died() abort
  echomsg 'gdbus monitor command died'
endfunction
