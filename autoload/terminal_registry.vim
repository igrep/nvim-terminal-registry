if !exists("s:registry")
  let s:registry = {}
endif

let s:_FAIL = -1

function! s:open_to_register(cmd, id, term_opts) abort
  enew
  let ref_to_term = {
        \ 'jobid': termopen(a:cmd, a:term_opts),
        \ 'bufnr': bufnr(''),
        \ }
  if ref_to_term.jobid < 0
    echoerr 'Failed to start terminal for ' . a:cmd
    return s:_FAIL
  endif
  set bufhidden=hide
  execute 'autocmd BufDelete <buffer=' . ref_to_term.bufnr . '> call terminal_registry#unregister(' . string(a:id) . ')'
  return ref_to_term
endfunction

function! terminal_registry#start(cmd, ...) abort
  let opts = get(a:, 1, {})
  let id = get(opts, "id", a:cmd)
  let kill = get(opts, "kill", 1)
  let term_opts = get(opts, "terminal_options", {})

  if has_key(s:registry, id)
    if kill
          \ && has_key(s:registry, id)
          \ && has_key(s:registry[id], 'bufnr')
          \ && bufexists(s:registry[id].bufnr)
      execute 'bdelete! ' . s:registry[id].bufnr
    else
      let s:registry[id] = s:open_to_register(a:cmd, id, term_opts)
      if s:registry[id] == s:_FAIL
        call remove(s:registry, id)
        return
      endif
      return s:registry[id]
    endif
  endif

  let s:registry[id] = s:open_to_register(a:cmd, id, term_opts)
  return s:registry[id]
endfunction

function! terminal_registry#get_buf(id) abort
  return s:registry[a:id].bufnr
endfunction

function! terminal_registry#switch(id) abort
  execute 'buffer ' . s:registry[a:id].bufnr
endfunction

function! terminal_registry#send(id, keys) abort
  call chansend(s:registry[a:id].jobid, a:keys)
endfunction

function! terminal_registry#sendl(id, keys) abort
  call chansend(s:registry[a:id].jobid, a:keys . "\n")
endfunction

function! terminal_registry#has_started(id) abort
  return has_key(s:registry, a:id)
endfunction

function! terminal_registry#unregister(id) abort
  if has_key(s:registry, a:id)
    call remove(s:registry, a:id)
  endif
endfunction

function! terminal_registry#get_recent_output_lines(id, n) abort
  let bufnr = s:registry[a:id].bufnr
  let bufinfo = getbufinfo(bufnr)[0]
  let endN = bufinfo.linecount
  while endN > 0 && getbufoneline(bufnr, endN) == ''
    let endN -= 1
  endwhile
  return join(getbufline(bufnr, max([1, endN - a:n + 1]), endN), "\n")
endfunction

function! terminal_registry#list() abort
  return keys(s:registry)
endfunction

function! terminal_registry#dump() abort
  echo s:registry
endfunction

function! terminal_registry#__clear() abort
  let s:registry = {}
endfunction
