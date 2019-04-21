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

function! s:open_to_register(cmd, tag, term_opts) abort
  let ref_to_term = s:term_open(a:cmd, a:term_opts)
  execute 'autocmd BufDelete <buffer=' . ref_to_term.bufnr . '> call terminal_registry#unregister(' . string(a:cmd) . ', { "tag": ' . string(a:tag) . '})'
  return ref_to_term
endfunction

function! s:get_or_register(cmd, tag, term_opts) abort
  if has_key(s:registry, a:cmd)
    let cmd_ref_by_tag = s:registry[a:cmd]
    if has_key(cmd_ref_by_tag, a:tag)
      return cmd_ref_by_tag[a:tag]
    endif

    let ref_to_term = s:open_to_register(a:cmd, a:tag, a:term_opts)
    let cmd_ref_by_tag[a:tag] = ref_to_term
    return ref_to_term
  endif

  let cmd_ref_by_tag = {}
  let cmd_ref_by_tag[a:tag] = s:open_to_register(a:cmd, a:tag, a:term_opts)
  let s:registry[a:cmd] = cmd_ref_by_tag
  return cmd_ref_by_tag[a:tag]
endfunction

function! s:inspect(arg) abort
  echomsg string(arg)
  return arg
endfunction

function! terminal_registry#start(cmd, ...) abort
  let opts = get(a:, 1, {})
  let tag = get(opts, "tag", "")
  let term_opts = get(opts, "terminal_options", {})
  call s:get_or_register(a:cmd, tag, term_opts)
endfunction

function! terminal_registry#open_or_switch(cmd, ...) abort
  let opts = get(a:, 1, {})
  let tag = get(opts, "tag", "")
  let term_opts = get(opts, "terminal_options", {})
  execute 'buffer ' . s:get_or_register(a:cmd, tag, term_opts).bufnr
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
  let tag = get(opts, "tag", "")
  let term_opts = get(opts, "terminal_options", {})

  call s:send_to(s:get_or_register(a:cmd, tag, term_opts), a:keys)
endfunction

function! terminal_registry#unregister(cmd, ...) abort
  let opts = get(a:, 1, {})
  let tag = get(opts, "tag", "")
  call remove(s:registry[a:cmd], tag)
endfunction

function! terminal_registry#dump() abort
  echo s:registry
endfunction

function! terminal_registry#__clear() abort
  let s:registry = {}
endfunction
