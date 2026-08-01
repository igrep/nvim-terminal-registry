if !exists("s:registry")
  let s:registry = {}
endif

if exists('*termopen')
  function! s:term_open(cmd, opts) abort
    enew
    let ref_to_term = {}
    let ref_to_term.jobid = termopen(a:cmd, a:opts)
    let ref_to_term.bufnr = bufnr('')
    set bufhidden=hide
    return ref_to_term
  endfunction
elseif exists('*term_start')
  function! s:term_open(cmd, opts) abort
    let ref_to_term = {}
    let ref_to_term.bufnr = term_start(a:cmd, a:opts)
    return ref_to_term
  endfunction
else
  echoerr "No terminal feature available!"
  finish
end

function! s:open_to_register(cmd, id, term_opts) abort
  let ref_to_term = s:term_open(a:cmd, a:term_opts)
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
      execute 'bdelete! ' . s:registry[id].bufnr
    else
      let s:registry[id] = s:open_to_register(a:cmd, id, term_opts)
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

if exists('*term_sendkeys')
  function! s:send_to(ref_to_term, keys, ...) abort
    call term_sendkeys(a:ref_to_term.bufnr, a:keys)
  endfunction
elseif exists('*chansend')
  function! s:send_to(ref_to_term, keys, ...) abort
    call chansend(a:ref_to_term.jobid, a:keys)
  endfunction
else
  echoerr "No terminal feature available!"
  finish
end

function! terminal_registry#send(id, keys) abort
  call s:send_to(s:registry[a:id], a:keys)
endfunction

function! terminal_registry#has_started(id) abort
  return has_key(s:registry, a:id)
endfunction

function! terminal_registry#unregister(id) abort
  if has_key(s:registry, a:id)
    call remove(s:registry, a:id)
  endif
endfunction

function! terminal_registry#dump() abort
  echo s:registry
endfunction

function! terminal_registry#__clear() abort
  let s:registry = {}
endfunction
