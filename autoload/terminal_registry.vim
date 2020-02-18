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
  execute 'autocmd BufDelete <buffer=' . ref_to_term.bufnr . '> call terminal_registry#unregister(' . string(a:cmd) . ', { "id": ' . string(a:id) . '})'
  return ref_to_term
endfunction

function! s:get_or_register(cmd, id, term_opts) abort
  if has_key(s:registry, a:id)
    return s:registry[a:id]
  endif

  let s:registry[a:id] = s:open_to_register(a:cmd, a:id, a:term_opts)
  return s:registry[a:id]
endfunction

function! s:inspect(arg) abort
  echomsg string(arg)
  return arg
endfunction

function! terminal_registry#start(cmd, ...) abort
  let opts = get(a:, 1, {})
  let id = get(opts, "id", a:cmd)
  let term_opts = get(opts, "terminal_options", {})
  call s:get_or_register(a:cmd, id, term_opts)
endfunction

function! terminal_registry#open_or_switch(cmd, ...) abort
  let opts = get(a:, 1, {})
  let id = get(opts, "id", a:cmd)
  let term_opts = get(opts, "terminal_options", {})
  execute 'buffer ' . s:get_or_register(a:cmd, id, term_opts).bufnr
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

function! terminal_registry#send(cmd, keys, ...) abort
  let opts = get(a:, 1, {})
  let id = get(opts, "id", a:cmd)
  let term_opts = get(opts, "terminal_options", {})

  call s:send_to(s:get_or_register(a:cmd, id, term_opts), a:keys)
endfunction

function! terminal_registry#unregister(cmd, ...) abort
  let opts = get(a:, 1, {})
  let id = get(opts, "id", a:cmd)
  if has_key(s:registry, id)
    call remove(s:registry, id)
  endif
endfunction

function! terminal_registry#dump() abort
  echo s:registry
endfunction

function! terminal_registry#__clear() abort
  let s:registry = {}
endfunction
