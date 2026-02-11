" rustlings_ko.vim - Main autoload interface
" Coordinates translation, caching, backend detection, and commands.
"
" Maintainer: rustlings-ko contributors
" License: MIT

let s:save_cpo = &cpo
set cpo&vim

let s:activated = 0
let s:detected_backend = ''

" ---------------------------------------------------------------------------
" Activation & Backend Detection
" ---------------------------------------------------------------------------

function! rustlings_ko#activate() abort
  if s:activated
    return
  endif
  let s:activated = 1

  " Initialize cache
  call rustlings_ko#cache#init(g:rustlings_ko_cache_max_size)

  " Detect and hook backend
  let s:detected_backend = s:detect_backend()

  if s:detected_backend ==# 'ale'
    call rustlings_ko#backend#ale#setup()
  elseif s:detected_backend ==# 'vim-lsp'
    call rustlings_ko#backend#vim_lsp#setup()
  elseif s:detected_backend ==# 'coc'
    call rustlings_ko#backend#coc#setup()
  endif

  " Always hook quickfix/loclist for :make / :compiler cargo support
  augroup rustlings_ko_qf
    autocmd!
    autocmd QuickFixCmdPost [^l]* call rustlings_ko#translate_quickfix()
    autocmd QuickFixCmdPost l* call rustlings_ko#translate_loclist()
  augroup END

  " Auto-check on save when no LSP backend is available
  if get(g:, 'rustlings_ko_auto_check', 1) && s:detected_backend ==# 'quickfix'
    call rustlings_ko#builder#setup()
  endif
endfunction

function! s:detect_backend() abort
  let l:pref = get(g:, 'rustlings_ko_backend', 'auto')
  if l:pref !=# 'auto'
    return l:pref
  endif

  " Auto-detect: vim-lsp > coc > ALE > quickfix
  if exists('*lsp#get_allowed_servers')
    return 'vim-lsp'
  elseif exists('*CocAction')
    return 'coc'
  elseif exists('*ale#engine#GetLoclist')
    return 'ale'
  else
    return 'quickfix'
  endif
endfunction

" ---------------------------------------------------------------------------
" Main Translation Function
" ---------------------------------------------------------------------------

function! rustlings_ko#translate(message) abort
  if !g:rustlings_ko_enabled
    return a:message
  endif
  if a:message ==# ''
    return a:message
  endif

  " 1. Check cache
  let l:cached = rustlings_ko#cache#get(a:message)
  if l:cached isnot v:null
    return rustlings_ko#translator#format_message(l:cached, a:message)
  endif

  " 2. Try mapping lookup (error codes + patterns)
  let l:translated = rustlings_ko#translator#translate(a:message)
  if l:translated isnot v:null
    call rustlings_ko#cache#set(a:message, l:translated)
    return rustlings_ko#translator#format_message(l:translated, a:message)
  endif

  " 3. Fire async LLM fallback if configured (result cached for next time)
  if g:rustlings_ko_mode ==# 'llm'
    call rustlings_ko#llm#translate_async(a:message, function('s:noop_callback'))
  endif

  " 4. Return original as final fallback
  return a:message
endfunction

function! s:noop_callback(translated) abort
  " LLM result is cached by llm.vim; will appear on next diagnostic refresh
endfunction

" ---------------------------------------------------------------------------
" Quickfix / Location List Translation
" ---------------------------------------------------------------------------

function! rustlings_ko#translate_quickfix() abort
  if !g:rustlings_ko_enabled
    return
  endif
  let l:items = getqflist()
  if s:translate_list_items(l:items)
    call setqflist(l:items, 'r')
  endif
endfunction

function! rustlings_ko#translate_loclist() abort
  if !g:rustlings_ko_enabled
    return
  endif
  let l:items = getloclist(0)
  if s:translate_list_items(l:items)
    call setloclist(0, l:items, 'r')
  endif
endfunction

function! s:translate_list_items(items) abort
  let l:changed = 0
  for l:item in a:items
    " Only translate Rust-related entries
    if l:item.bufnr > 0
      let l:ft = getbufvar(l:item.bufnr, '&filetype', '')
      if l:ft !=# 'rust' && l:ft !=# ''
        continue
      endif
    endif

    " Reconstruct message with error code if .nr is available
    " (errorformat %n extracts error number into .nr, e.g. E0308 -> nr=308)
    let l:msg = l:item.text
    if l:item.nr > 0
      let l:msg = printf('[E%04d]: %s', l:item.nr, l:item.text)
    endif

    let l:translated = rustlings_ko#translate(l:msg)
    if l:translated !=# l:msg
      let l:item.text = l:translated
      let l:changed = 1
    endif
  endfor
  return l:changed
endfunction

" ---------------------------------------------------------------------------
" Commands
" ---------------------------------------------------------------------------

function! rustlings_ko#command(cmd) abort
  if a:cmd ==# 'enable'
    call rustlings_ko#enable()
    echomsg '[rustlings-ko] 활성화되었습니다'
  elseif a:cmd ==# 'disable'
    call rustlings_ko#disable()
    echomsg '[rustlings-ko] 비활성화되었습니다'
  elseif a:cmd ==# 'toggle'
    call rustlings_ko#toggle()
    let l:state = g:rustlings_ko_enabled ? '활성화' : '비활성화'
    echomsg '[rustlings-ko] ' . l:state . '되었습니다'
  elseif a:cmd ==# 'clear-cache'
    call rustlings_ko#cache#clear()
    echomsg '[rustlings-ko] 캐시가 초기화되었습니다'
  elseif a:cmd ==# 'status'
    call rustlings_ko#status()
  else
    echohl WarningMsg
    echomsg '[rustlings-ko] 사용법: :RustDiagKo {enable|disable|toggle|clear-cache|status}'
    echohl None
  endif
endfunction

function! rustlings_ko#complete(ArgLead, CmdLine, CursorPos) abort
  return filter(['enable', 'disable', 'toggle', 'clear-cache', 'status'],
        \ 'v:val =~# "^" . a:ArgLead')
endfunction

function! rustlings_ko#enable() abort
  let g:rustlings_ko_enabled = 1
endfunction

function! rustlings_ko#disable() abort
  let g:rustlings_ko_enabled = 0
endfunction

function! rustlings_ko#toggle() abort
  let g:rustlings_ko_enabled = !g:rustlings_ko_enabled
endfunction

function! rustlings_ko#status() abort
  echomsg '[rustlings-ko] 상태:'
  echomsg '  활성화: ' . (g:rustlings_ko_enabled ? '예' : '아니오')
  echomsg '  모드: ' . g:rustlings_ko_mode
  echomsg '  백엔드: ' . (s:detected_backend !=# '' ? s:detected_backend : '미감지')
  echomsg '  자동 빌드: ' . (s:detected_backend ==# 'quickfix' && get(g:, 'rustlings_ko_auto_check', 1) ? '예 (저장 시 cargo check)' : '아니오')
  echomsg '  캐시 크기: ' . rustlings_ko#cache#size() . '/' . g:rustlings_ko_cache_max_size
  if g:rustlings_ko_mode ==# 'llm'
    echomsg '  LLM 프로바이더: ' . g:rustlings_ko_llm_provider
    echomsg '  API 키 설정: ' . (empty(g:rustlings_ko_llm_api_key) ? '아니오' : '예')
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
