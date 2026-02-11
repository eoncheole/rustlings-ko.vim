" rustlings-ko.vim - Rust 진단 메시지 한국어 번역 플러그인
" Plugin entry point (Vim 8.2+)
"
" Maintainer: rustlings-ko contributors
" License: MIT

" Guard: only load once, respect 'compatible' mode
if exists('g:loaded_rustlings_ko') || &cp
  finish
endif

" Require Vim 8.2+
if v:version < 802
  echohl WarningMsg
  echomsg '[rustlings-ko] Vim 8.2 이상이 필요합니다'
  echohl None
  finish
endif

let g:loaded_rustlings_ko = 1

" Save cpo and reset to Vim default
let s:save_cpo = &cpo
set cpo&vim

" ---------------------------------------------------------------------------
" Configuration variables with defaults
" ---------------------------------------------------------------------------

" Master on/off switch
let g:rustlings_ko_enabled = get(g:, 'rustlings_ko_enabled', 1)

" Translation mode: 'mapping' = offline only, 'llm' = mapping + LLM fallback
let g:rustlings_ko_mode = get(g:, 'rustlings_ko_mode', 'mapping')

" Whether to append the original English message below the translation
let g:rustlings_ko_show_original = get(g:, 'rustlings_ko_show_original', 0)

" Maximum number of entries in the LRU translation cache
let g:rustlings_ko_cache_max_size = get(g:, 'rustlings_ko_cache_max_size', 500)

" LLM provider: 'anthropic' or 'openai' (only used when mode == 'llm')
let g:rustlings_ko_llm_provider = get(g:, 'rustlings_ko_llm_provider', '')

" LLM API key (only used when mode == 'llm')
let g:rustlings_ko_llm_api_key = get(g:, 'rustlings_ko_llm_api_key', '')

" Backend for hooking into diagnostics:
"   'auto' - detect best available backend
"   'ale'  - ALE (dense-analysis/ale)
"   'vim-lsp' - vim-lsp (prabirshrestha/vim-lsp)
"   'coc'  - coc.nvim (neoclide/coc.nvim)
"   'quickfix' - translate quickfix/location lists only
let g:rustlings_ko_backend = get(g:, 'rustlings_ko_backend', 'auto')

" Printf-style format for translated diagnostics
let g:rustlings_ko_diagnostics_format = get(g:, 'rustlings_ko_diagnostics_format', '%s')

" Printf-style format for appended original message
let g:rustlings_ko_original_format = get(g:, 'rustlings_ko_original_format', "\n[원문] %s")

" Auto-check on save: run cargo check when no LSP backend is detected
let g:rustlings_ko_auto_check = get(g:, 'rustlings_ko_auto_check', 1)

" ---------------------------------------------------------------------------
" Commands
" ---------------------------------------------------------------------------

command! -nargs=1 -complete=customlist,rustlings_ko#complete
      \ RustDiagKo call rustlings_ko#command(<f-args>)

" ---------------------------------------------------------------------------
" Autocommands: activate when a Rust file is opened
" ---------------------------------------------------------------------------

augroup rustlings_ko
  autocmd!
  autocmd FileType rust call rustlings_ko#activate()
augroup END

" Restore cpo
let &cpo = s:save_cpo
unlet s:save_cpo
