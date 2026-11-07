" Fallback when the system appearance cannot be read.
" Returns 'dark' from 19:00 until 06:00 and 'light' otherwise, for {hour}
" or the current local hour.
let s:dark_from = 19
let s:light_from = 6

function! daybreak#clock#background(...) abort
  let hour = a:0 > 0 ? a:1 : str2nr(strftime('%H'))
  return hour >= s:dark_from || hour < s:light_from ? 'dark' : 'light'
endfunction
