" rustlings_ko/backend/coc.vim - coc.nvim (neoclide/coc.nvim) integration
" Translates diagnostics surfaced by coc.nvim into Korean.
" Replaces coc's virtual text with Korean translations and provides
" a translated hover popup.
"
" Maintainer: rustlings-ko contributors
" License: MIT

let s:save_cpo = &cpo
set cpo&vim

let s:setup_done = 0
let s:timer_delay = 100
let s:prop_types = {}
let s:has_virtual_text = v:false

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

  " Check if prop_add() supports 'text' parameter (Vim 9.0.0067+)
  let s:has_virtual_text = has('patch-9.0.0067')

  augroup rustlings_ko_coc
    autocmd!
    autocmd User CocDiagnosticChange call s:on_diagnostic_change()
  augroup END

  " Override K mapping for Rust files to show translated hover
  augroup rustlings_ko_coc_hover
    autocmd!
    autocmd FileType rust nnoremap <buffer> <silent> K :call rustlings_ko#backend#coc#hover()<CR>
  augroup END
endfunction

function! rustlings_ko#backend#coc#teardown() abort
  augroup rustlings_ko_coc
    autocmd!
  augroup END
  augroup rustlings_ko_coc_hover
    autocmd!
  augroup END
  let s:setup_done = 0
endfunction

" ---------------------------------------------------------------------------
" Hover: show translated diagnostic popup on K press
" ---------------------------------------------------------------------------

function! rustlings_ko#backend#coc#hover() abort
  if !get(g:, 'rustlings_ko_enabled', 1)
    call CocActionAsync('doHover')
    return
  endif

  let l:lnum = line('.')
  let l:file = expand('%:p')
  let l:messages = []

  try
    let l:diags = CocAction('diagnosticList')
    for l:d in l:diags
      if get(l:d, 'file', '') !=# l:file || get(l:d, 'lnum', 0) != l:lnum
        continue
      endif

      let l:msg = get(l:d, 'message', '')
      let l:translated = rustlings_ko#translate(l:msg)
      let l:severity = get(l:d, 'severity', 'Error')
      let l:sev_map = {'Error': '에러', 'Warning': '경고', 'Information': '정보', 'Hint': '힌트'}
      let l:sev_ko = get(l:sev_map, l:severity, '')
      let l:code = get(l:d, 'code', '')

      let l:line = ''
      if l:sev_ko !=# ''
        let l:line .= '[' . l:sev_ko . '] '
      endif
      let l:line .= l:translated
      if l:code !=# ''
        let l:line .= ' (' . l:code . ')'
      endif
      call add(l:messages, l:line)

      " Show original if configured
      if get(g:, 'rustlings_ko_show_original', 0) && l:translated !=# l:msg
        call add(l:messages, '[원문] ' . l:msg)
      endif
    endfor
  catch
  endtry

  if empty(l:messages)
    " No diagnostics at cursor - fall back to coc hover for docs
    call CocActionAsync('doHover')
    return
  endif

  call popup_atcursor(l:messages, {
        \ 'border': [1,1,1,1],
        \ 'padding': [0,1,0,1],
        \ 'maxwidth': 80,
        \ 'highlight': 'Normal',
        \ 'borderhighlight': ['Comment'],
        \ })
endfunction

" ---------------------------------------------------------------------------
" Diagnostic change handler
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
  " 1. Translate loclist/quickfix
  call s:translate_list('loc')
  call s:translate_list('qf')

  " 2. Replace coc's virtual text with Korean
  if s:has_virtual_text
    call s:replace_virtual_text()
  endif
endfunction

" ---------------------------------------------------------------------------
" Virtual Text: replace coc's English virtual text with Korean
" ---------------------------------------------------------------------------

function! s:replace_virtual_text() abort
  let l:bufnr = bufnr('%')

  " Remove coc's English virtual text
  for l:coc_type in ['CocErrorVirtualText', 'CocWarningVirtualText',
        \ 'CocInfoVirtualText', 'CocHintVirtualText']
    try
      call prop_remove({'type': l:coc_type, 'bufnr': l:bufnr, 'all': v:true})
    catch
    endtry
  endfor

  " Remove our previous translated virtual text
  call s:clear_props(l:bufnr)

  " Get diagnostics from coc
  try
    let l:diags = CocAction('diagnosticList')
  catch
    return
  endtry
  if empty(l:diags)
    return
  endif

  let l:file = expand('%:p')
  for l:d in l:diags
    if get(l:d, 'file', '') !=# l:file
      continue
    endif

    let l:msg = get(l:d, 'message', '')
    let l:translated = rustlings_ko#translate(l:msg)
    let l:severity = get(l:d, 'severity', 'Error')
    let l:hl = s:severity_highlight(l:severity)
    let l:prop_type = s:ensure_prop_type(l:hl)

    try
      call prop_add(get(l:d, 'lnum', 1), 0, {
            \ 'type': l:prop_type,
            \ 'text': '  ' . l:translated,
            \ 'text_align': 'after',
            \ 'bufnr': l:bufnr,
            \ })
    catch
      " Silently fail if prop_add with 'text' not supported
      return
    endtry
  endfor
endfunction

function! s:severity_highlight(severity) abort
  if a:severity ==# 'Error'
    return 'CocErrorVirtualText'
  elseif a:severity ==# 'Warning'
    return 'CocWarningVirtualText'
  elseif a:severity ==# 'Information'
    return 'CocInfoVirtualText'
  endif
  return 'CocHintVirtualText'
endfunction

function! s:ensure_prop_type(highlight) abort
  let l:name = 'RustlingsKo_' . a:highlight
  if !has_key(s:prop_types, l:name)
    try
      call prop_type_add(l:name, {'highlight': a:highlight})
    catch
    endtry
    let s:prop_types[l:name] = 1
  endif
  return l:name
endfunction

function! s:clear_props(bufnr) abort
  for l:name in keys(s:prop_types)
    try
      call prop_remove({'type': l:name, 'bufnr': a:bufnr, 'all': v:true})
    catch
    endtry
  endfor
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
