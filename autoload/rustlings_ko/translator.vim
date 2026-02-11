" rustlings_ko/translator.vim - Translation engine
" Delegates to mappings.vim for lookup, provides format_message.
"
" Maintainer: rustlings-ko contributors
" License: MIT

let s:save_cpo = &cpo
set cpo&vim

" Main translation function: delegates to mappings lookup.
" Returns translated string, or v:null if no translation found.
function! rustlings_ko#translator#translate(message) abort
  if a:message ==# ''
    return v:null
  endif
  return rustlings_ko#mappings#lookup(a:message)
endfunction

" Format the translated message, optionally appending the original.
function! rustlings_ko#translator#format_message(translated, original) abort
  let l:fmt = get(g:, 'rustlings_ko_diagnostics_format', '%s')
  let l:result = printf(l:fmt, a:translated)

  if get(g:, 'rustlings_ko_show_original', 0) && a:translated !=# a:original
    let l:orig_fmt = get(g:, 'rustlings_ko_original_format', "\n[원문] %s")
    let l:result .= printf(l:orig_fmt, a:original)
  endif

  return l:result
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
