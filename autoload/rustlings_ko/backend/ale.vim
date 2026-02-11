" rustlings_ko/backend/ale.vim - ALE linter integration
" Translates rust-analyzer / cargo / rustc diagnostics from ALE into Korean.
"
" Maintainer: rustlings-ko contributors
" License: MIT

let s:save_cpo = &cpo
set cpo&vim

let s:setup_done = 0

" Linter names that produce Rust compiler diagnostics.
let s:rust_linters = {'rust_analyzer': 1, 'cargo': 1, 'rustc': 1}

function! s:is_rust_linter(name) abort
  return has_key(s:rust_linters, a:name)
endfunction

" ---------------------------------------------------------------------------
" Public API
" ---------------------------------------------------------------------------

function! rustlings_ko#backend#ale#setup() abort
  if !exists('g:loaded_ale')
    return
  endif
  if s:setup_done
    return
  endif
  let s:setup_done = 1

  augroup rustlings_ko_ale
    autocmd!
    autocmd User ALELintPost call s:translate_ale_diagnostics()
  augroup END
endfunction

function! rustlings_ko#backend#ale#teardown() abort
  augroup rustlings_ko_ale
    autocmd!
  augroup END
  let s:setup_done = 0
endfunction

" ---------------------------------------------------------------------------
" Private
" ---------------------------------------------------------------------------

function! s:translate_ale_diagnostics() abort
  if !get(g:, 'rustlings_ko_enabled', 1)
    return
  endif

  if &filetype !=# 'rust'
    return
  endif

  let l:buf = bufnr('%')

  " 1. Translate ALE's internal loclist
  if exists('*ale#engine#GetLoclist')
    let l:ale_list = ale#engine#GetLoclist(l:buf)
    for l:item in l:ale_list
      if !has_key(l:item, 'linter_name') || !s:is_rust_linter(l:item.linter_name)
        continue
      endif
      let l:translated = rustlings_ko#translate(l:item.text)
      if l:translated !=# l:item.text
        let l:item.text = l:translated
      endif
    endfor
  endif

  " 2. Translate the location list (if ALE populates it)
  if get(g:, 'ale_set_loclist', 1)
    call s:translate_list('loc')
  endif

  " 3. Translate the quickfix list (if ALE populates it)
  if get(g:, 'ale_set_quickfix', 0)
    call s:translate_list('qf')
  endif
endfunction

function! s:translate_list(kind) abort
  if a:kind ==# 'loc'
    let l:items = getloclist(0)
  else
    let l:items = getqflist()
  endif

  if empty(l:items)
    return
  endif

  let l:changed = 0
  for l:item in l:items
    if l:item.bufnr > 0
      let l:ft = getbufvar(l:item.bufnr, '&filetype', '')
      if l:ft !=# 'rust'
        continue
      endif
    endif

    let l:translated = rustlings_ko#translate(l:item.text)
    if l:translated !=# l:item.text
      let l:item.text = l:translated
      let l:changed = 1
    endif
  endfor

  if l:changed
    if a:kind ==# 'loc'
      call setloclist(0, l:items, 'r')
    else
      call setqflist(l:items, 'r')
    endif
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
