function! terminal_registry#start(cmd, ...) abort
  let opts = get(a:, 1, {})
  return v:lua.require('terminal_registry').start(a:cmd, opts)
endfunction

function! terminal_registry#switch(id) abort
  return v:lua.require('terminal_registry').switch(a:id)
endfunction

function! terminal_registry#send(id, keys) abort
  return v:lua.require('terminal_registry').send(a:id, a:keys)
endfunction

function! terminal_registry#sendl(id, keys) abort
  return v:lua.require('terminal_registry').sendl(a:id, a:keys)
endfunction

function! terminal_registry#has_started(id) abort
  return v:lua.require('terminal_registry').has_started(a:id)
endfunction

function! terminal_registry#kill(id) abort
  return v:lua.require('terminal_registry').kill(a:id)
endfunction
