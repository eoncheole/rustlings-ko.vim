" rustlings_ko/backend/vim_lsp.vim - vim-lsp (prabirshrestha/vim-lsp) integration
" Translates LSP diagnostics displayed via vim-lsp into Korean.
"
" Maintainer: rustlings-ko contributors
" License: MIT

let s:save_cpo = &cpo
set cpo&vim

let s:setup_done = 0
let s:timer_delay = 50

" ---------------------------------------------------------------------------
" Public API
" ---------------------------------------------------------------------------

function! rustlings_ko#backend#vim_lsp#setup() abort
  if !exists('g:lsp_loaded')
    return
  endif
  if s:setup_done
    return
  endif
  let s:setup_done = 1

  augroup rustlings_ko_vim_lsp
    autocmd!
    autocmd User lsp_diagnostics_updated call s:on_diagnostics_updated()
  augroup END
endfunction

function! rustlings_ko#backend#vim_lsp#teardown() abort
  augroup rustlings_ko_vim_lsp
    autocmd!
  augroup END
  let s:setup_done = 0
endfunction

" ---------------------------------------------------------------------------
" Private
" ---------------------------------------------------------------------------

function! s:on_diagnostics_updated() abort
  if !get(g:, 'rustlings_ko_enabled', 1)
    return
  endif
  if &filetype !=# 'rust'
    return
  endif

  if exists('*timer_start')
    call timer_start(s:timer_delay, function('s:translate_vim_lsp_diagnostics'))
  else
    call s:translate_vim_lsp_diagnostics(0)
  endif
endfunction

function! s:translate_vim_lsp_diagnostics(timer_id) abort
  " 1. Location list
  let l:loclist = getloclist(0)
  if !empty(l:loclist)
    let l:changed = 0
    for l:item in l:loclist
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
      call setloclist(0, l:loclist, 'r')
    endif
  endif

  " 2. Quickfix list
  let l:qflist = getqflist()
  if !empty(l:qflist)
    let l:qf_changed = 0
    for l:item in l:qflist
      if l:item.bufnr > 0
        let l:ft = getbufvar(l:item.bufnr, '&filetype', '')
        if l:ft !=# 'rust'
          continue
        endif
      endif

      let l:translated = rustlings_ko#translate(l:item.text)
      if l:translated !=# l:item.text
        let l:item.text = l:translated
        let l:qf_changed = 1
      endif
    endfor

    if l:qf_changed
      call setqflist(l:qflist, 'r')
    endif
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
