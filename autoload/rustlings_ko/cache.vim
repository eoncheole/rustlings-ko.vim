" rustlings_ko/cache.vim - LRU cache implementation
" Uses a dict for O(1) lookup and a list for LRU ordering.
"
" Maintainer: rustlings-ko contributors
" License: MIT

let s:save_cpo = &cpo
set cpo&vim

" ---------------------------------------------------------------------------
" Module state (singleton cache)
" ---------------------------------------------------------------------------

let s:entries = {}
let s:order = []
let s:max_size = 500
let s:initialized = 0

" ---------------------------------------------------------------------------
" Public API
" ---------------------------------------------------------------------------

function! rustlings_ko#cache#init(max_size) abort
  if s:initialized && s:max_size ==# a:max_size
    return
  endif
  let s:max_size = a:max_size > 0 ? a:max_size : 500
  let s:initialized = 1
endfunction

function! rustlings_ko#cache#get(key) abort
  if !has_key(s:entries, a:key)
    return v:null
  endif
  call s:touch(a:key)
  return s:entries[a:key]
endfunction

function! rustlings_ko#cache#set(key, value) abort
  if has_key(s:entries, a:key)
    let s:entries[a:key] = a:value
    call s:touch(a:key)
    return
  endif

  if len(s:order) >= s:max_size
    call s:evict()
  endif

  let s:entries[a:key] = a:value
  call add(s:order, a:key)
endfunction

function! rustlings_ko#cache#clear() abort
  let s:entries = {}
  let s:order = []
endfunction

function! rustlings_ko#cache#size() abort
  return len(s:order)
endfunction

" ---------------------------------------------------------------------------
" Internal helpers
" ---------------------------------------------------------------------------

function! s:touch(key) abort
  let l:idx = index(s:order, a:key)
  if l:idx >= 0
    call remove(s:order, l:idx)
  endif
  call add(s:order, a:key)
endfunction

function! s:evict() abort
  if empty(s:order)
    return
  endif
  let l:oldest = remove(s:order, 0)
  if has_key(s:entries, l:oldest)
    call remove(s:entries, l:oldest)
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
