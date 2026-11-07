function! daybreak#windows#setup(Light, Dark) abort
  let output = system('reg query'
        \ . ' HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize'
        \ . ' /v AppsUseLightTheme')
  if v:shell_error != 0
    echomsg 'reg command failed'
    return
  endif
  let match = matchlist(output, 'AppsUseLightTheme\s\+REG_DWORD\s\+0x\(\d\+\)')
  if empty(match)
    echomsg 'unrecognized registry value'
    return
  endif
  if match[1] ==# '1'
    call a:Light()
  else
    call a:Dark()
  endif
endfunction
