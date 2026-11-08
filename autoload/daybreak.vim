" Matches the editor background with the system dark/light appearance.
function! daybreak#setup(...) abort
  if get(g:, 'daybreak_did_setup', 0)
    return
  endif
  let g:daybreak_did_setup = 1

  let opts = a:0 > 0 ? a:1 : {}
  let Light = function('daybreak#apply',
        \ ['light', get(opts, 'light', get(g:, 'daybreak_light', ''))])
  let Dark = function('daybreak#apply',
        \ ['dark', get(opts, 'dark', get(g:, 'daybreak_dark', ''))])

  if has('osx') || has('mac') || has('macunix')
    call daybreak#macos#setup(Light, Dark)
  elseif has('win32') || has('win64')
    call daybreak#windows#setup(Light, Dark)
  elseif !s:has_desktop_session()
    call s:apply_by_clock(Light, Dark)
  elseif executable('gdbus')
    call daybreak#gdbus#setup(Light, Dark)
  else
    call s:apply_by_clock(Light, Dark)
  endif
endfunction

function! daybreak#apply(background, theme) abort
  let &background = a:background
  if !empty(a:theme)
    execute 'colorscheme' a:theme
  endif
endfunction

function! s:has_desktop_session() abort
  if has('gui_running')
    return 1
  endif
  return !empty($WAYLAND_DISPLAY) || !empty($DISPLAY) || !empty($MIR_SOCKET)
endfunction

function! s:apply_by_clock(Light, Dark) abort
  if daybreak#clock#background() ==# 'dark'
    call a:Dark()
  else
    call a:Light()
  endif
endfunction
