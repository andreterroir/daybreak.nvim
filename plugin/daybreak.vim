if has('nvim')
  finish
endif
if exists('g:loaded_daybreak')
  finish
endif
let g:loaded_daybreak = 1

call daybreak#setup()
