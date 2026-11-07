" Resolved while sourcing: inside a function <sfile> is the caller's file.
let s:root = expand('<sfile>:p:h:h:h')

function! daybreak#macos#setup(Light, Dark) abort
  " Succeeds with output 'Dark' in dark mode and fails otherwise.
  call system('defaults read -g AppleInterfaceStyle')
  if v:shell_error == 0
    call a:Dark()
  else
    call a:Light()
  endif

  let watcher = s:root . '/appearance'
  if !executable(watcher)
    if !executable('swiftc')
      return
    endif
    call system('swiftc ' . shellescape(s:root . '/macos/appearance.swift')
          \ . ' -o ' . shellescape(watcher))
    if v:shell_error != 0
      echomsg 'watcher compilation failed'
      return
    endif
  endif

  call daybreak#job#start([watcher], {
        \ 'on_line': function('s:change', [a:Light, a:Dark]),
        \ 'on_exit': function('s:watcher_died'),
        \ })
endfunction

function! s:change(Light, Dark, line) abort
  if a:line ==# 'light'
    call a:Light()
  elseif a:line ==# 'dark'
    call a:Dark()
  endif
endfunction

function! s:watcher_died() abort
  echomsg 'appearance watcher died'
endfunction
