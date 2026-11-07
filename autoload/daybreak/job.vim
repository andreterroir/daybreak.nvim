" Starts a line-oriented job. Neovim hands over a list of lines per chunk and
" leaves trailing fragments for the next call, Vim calls out_cb once per line.
function! daybreak#job#start(command, callbacks) abort
  let state = {'tail': '', 'on_line': a:callbacks.on_line,
        \ 'on_exit': a:callbacks.on_exit}
  if has('nvim')
    call jobstart(a:command, {
          \ 'on_stdout': function('s:nvim_stdout', [state]),
          \ 'on_exit': function('s:nvim_exit', [state]),
          \ })
  elseif has('job')
    call job_start(a:command, {
          \ 'out_cb': function('s:vim_line', [state]),
          \ 'close_cb': function('s:vim_exit', [state]),
          \ })
  endif
endfunction

function! s:nvim_stdout(state, _id, data, _event) abort
  let lines = a:data
  let first = a:state.tail . lines[0]
  if len(lines) == 1
    let a:state.tail = first
    return
  endif
  call a:state.on_line(first)
  for line in lines[1 : -2]
    call a:state.on_line(line)
  endfor
  let a:state.tail = lines[-1]
endfunction

function! s:nvim_exit(state, _id, _code, _event) abort
  call a:state.on_exit()
endfunction

function! s:vim_line(state, _channel, msg) abort
  call a:state.on_line(a:msg)
endfunction

function! s:vim_exit(state, _channel) abort
  call a:state.on_exit()
endfunction
