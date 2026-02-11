" rustlings_ko/backend/coc.vim - coc.nvim (neoclide/coc.nvim) integration
" Korean diagnostic display for Rust files:
"   - CursorHold auto-popup (replaces coc's diagnostic float)
"   - K key hover popup
"   - Quickfix/loclist translation
"
" Maintainer: rustlings-ko contributors
" License: MIT

let s:save_cpo = &cpo
set cpo&vim

let s:setup_done = 0
let s:timer_delay = 100
let s:popup_id = 0

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
    " Translate on diagnostic change
    autocmd User CocDiagnosticChange call s:on_diagnostic_change()
    " Auto-popup Korean diagnostic on cursor hold
    autocmd CursorHold *.rs call s:show_diagnostic_float()
    " K key for Korean hover on Rust files
    autocmd FileType rust nnoremap <buffer> <silent> K :call <SID>show_diagnostic_float_or_hover()<CR>
  augroup END
endfunction

function! rustlings_ko#backend#coc#teardown() abort
  augroup rustlings_ko_coc
    autocmd!
  augroup END
  let s:setup_done = 0
endfunction

" ---------------------------------------------------------------------------
" Diagnostic Float (CursorHold auto-popup + K key)
" ---------------------------------------------------------------------------

function! s:show_diagnostic_float() abort
  if !get(g:, 'rustlings_ko_enabled', 1) || &filetype !=# 'rust'
    return
  endif

  " Close previous popup
  if s:popup_id > 0
    try
      call popup_close(s:popup_id)
    catch
    endtry
    let s:popup_id = 0
  endif

  let l:lines = s:get_translated_diagnostics_at_cursor()
  if empty(l:lines)
    return
  endif

  let s:popup_id = popup_atcursor(l:lines, {
        \ 'border': [1,1,1,1],
        \ 'padding': [0,1,0,1],
        \ 'maxwidth': 80,
        \ 'moved': 'any',
        \ 'highlight': 'Normal',
        \ 'borderhighlight': ['Comment'],
        \ })
endfunction

" K key: show diagnostic if on error line, otherwise show coc hover docs
function! s:show_diagnostic_float_or_hover() abort
  if !get(g:, 'rustlings_ko_enabled', 1)
    call CocActionAsync('doHover')
    return
  endif

  let l:lines = s:get_translated_diagnostics_at_cursor()
  if empty(l:lines)
    " No diagnostics - fall back to coc documentation hover
    call CocActionAsync('doHover')
    return
  endif

  " Close previous popup
  if s:popup_id > 0
    try
      call popup_close(s:popup_id)
    catch
    endtry
  endif

  let s:popup_id = popup_atcursor(l:lines, {
        \ 'border': [1,1,1,1],
        \ 'padding': [0,1,0,1],
        \ 'maxwidth': 80,
        \ 'moved': 'any',
        \ 'highlight': 'Normal',
        \ 'borderhighlight': ['Comment'],
        \ })
endfunction

" Get translated diagnostic message at the exact cursor position
function! s:get_translated_diagnostics_at_cursor() abort
  let l:lnum = line('.')
  let l:col = col('.')
  let l:file = expand('%:p')
  let l:lines = []

  try
    let l:diags = CocAction('diagnosticList')
  catch
    return []
  endtry

  for l:d in l:diags
    if get(l:d, 'file', '') !=# l:file || get(l:d, 'lnum', 0) != l:lnum
      continue
    endif

    " Filter by cursor column: only show if cursor is within the diagnostic range
    let l:d_col = get(l:d, 'col', 1)
    let l:d_end = get(l:d, 'end_col', l:d_col)
    if l:col < l:d_col || l:col > l:d_end
      continue
    endif

    let l:msg = get(l:d, 'message', '')
    let l:translated = rustlings_ko#translate_raw(l:msg)
    let l:severity = get(l:d, 'severity', 'Error')
    let l:sev_map = {'Error': '에러', 'Warning': '경고', 'Information': '정보', 'Hint': '힌트'}
    let l:sev_ko = get(l:sev_map, l:severity, l:severity)
    let l:code = get(l:d, 'code', '')

    " Separator between multiple diagnostics
    if !empty(l:lines)
      call add(l:lines, '─────────────────────────')
    endif

    " Header: [에러 E0308]
    let l:header = l:sev_ko
    if l:code !=# ''
      let l:header .= ' ' . l:code
    endif
    call add(l:lines, '[' . l:header . ']')

    " Translated message
    call add(l:lines, l:translated)

    " Original if configured
    if get(g:, 'rustlings_ko_show_original', 0) && l:translated !=# l:msg
      call add(l:lines, '')
      call add(l:lines, '[원문] ' . l:msg)
    endif
  endfor

  return l:lines
endfunction

" ---------------------------------------------------------------------------
" Diagnostic change: loclist/quickfix translation
" ---------------------------------------------------------------------------

function! s:on_diagnostic_change() abort
  if !get(g:, 'rustlings_ko_enabled', 1) || &filetype !=# 'rust'
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

" ---------------------------------------------------------------------------
" Loclist/Quickfix Translation
" ---------------------------------------------------------------------------

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
