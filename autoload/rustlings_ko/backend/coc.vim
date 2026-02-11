" rustlings_ko/backend/coc.vim - coc.nvim (neoclide/coc.nvim) integration
" Translates diagnostics surfaced by coc.nvim into Korean.
"
" Maintainer: rustlings-ko contributors
" License: MIT

let s:save_cpo = &cpo
set cpo&vim

let s:setup_done = 0
let s:timer_delay = 80

" ---------------------------------------------------------------------------
" Public API
" ---------------------------------------------------------------------------

function! rustlings_ko#backend#coc#setup() abort
  if !exists('g:did_coc_loaded')
    return
  endif
  if s:setup_done
    return
  endif
  let s:setup_done = 1

  augroup rustlings_ko_coc
    autocmd!
    autocmd User CocDiagnosticChange call s:on_diagnostic_change()
  augroup END
endfunction

function! rustlings_ko#backend#coc#teardown() abort
  augroup rustlings_ko_coc
    autocmd!
  augroup END
  let s:setup_done = 0
endfunction

" ---------------------------------------------------------------------------
" Private
" ---------------------------------------------------------------------------

function! s:on_diagnostic_change() abort
  if !get(g:, 'rustlings_ko_enabled', 1)
    return
  endif
  if &filetype !=# 'rust'
    return
  endif

  if exists('*timer_start')
    call timer_start(s:timer_delay, function('s:translate_coc_diagnostics'))
  else
    call s:translate_coc_diagnostics(0)
  endif
endfunction

function! s:translate_coc_diagnostics(timer_id) abort
  call s:translate_list('loc')
  call s:translate_list('qf')
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
