" rustlings_ko/builder.vim - Async cargo check on file save
" Runs cargo check asynchronously when a Rust file is saved,
" populating the quickfix list with translated diagnostics.
"
" Maintainer: rustlings-ko contributors
" License: MIT

let s:save_cpo = &cpo
set cpo&vim

let s:job = v:null
let s:output = []

" Custom errorformat for cargo output - preserves error codes in .nr field
let s:cargo_errorformat =
      \ '%Eerror[E%n]: %m,' .
      \ '%-Gerror: aborting %.%#,' .
      \ '%-GFor more information%.%#,' .
      \ '%Eerror: %m,' .
      \ '%Wwarning[%*[a-z_-]]: %m,' .
      \ '%Wwarning: %m,' .
      \ '%Inote: %m,' .
      \ '%Z %#--> %f:%l:%c,' .
      \ '%-G%.%#'

" ---------------------------------------------------------------------------
" Public API
" ---------------------------------------------------------------------------

function! rustlings_ko#builder#setup() abort
  augroup rustlings_ko_builder
    autocmd!
    autocmd BufWritePost *.rs call rustlings_ko#builder#run()
  augroup END
endfunction

function! rustlings_ko#builder#teardown() abort
  augroup rustlings_ko_builder
    autocmd!
  augroup END
  call s:stop_job()
endfunction

function! rustlings_ko#builder#run() abort
  if !get(g:, 'rustlings_ko_enabled', 1)
    return
  endif

  let l:root = s:find_cargo_root(expand('%:p:h'))
  if l:root ==# ''
    return
  endif

  " Cancel previous check if still running
  call s:stop_job()
  let s:output = []

  let s:job = job_start(['cargo', 'check'], {
        \ 'err_io': 'out',
        \ 'out_cb': function('s:on_output'),
        \ 'exit_cb': function('s:on_exit'),
        \ 'cwd': l:root,
        \ })

  if job_status(s:job) ==# 'fail'
    let s:job = v:null
  endif
endfunction

" ---------------------------------------------------------------------------
" Private
" ---------------------------------------------------------------------------

function! s:on_output(ch, msg) abort
  " Strip ANSI color codes
  call add(s:output, substitute(a:msg, '\e\[[0-9;]*m', '', 'g'))
endfunction

function! s:on_exit(job, status) abort
  " Use timer to ensure safe context for quickfix operations
  call timer_start(0, function('s:apply_results'))
endfunction

function! s:apply_results(timer_id) abort
  let l:save_efm = &errorformat
  let &errorformat = s:cargo_errorformat

  " cgetexpr populates quickfix and triggers QuickFixCmdPost -> translation
  cgetexpr s:output

  let &errorformat = l:save_efm

  " Open quickfix if errors exist, close if build is clean
  let l:has_errors = !empty(filter(getqflist(), 'v:val.valid'))
  if l:has_errors
    botright cwindow
  else
    cclose
  endif
endfunction

function! s:stop_job() abort
  if s:job isnot v:null
    try
      if job_status(s:job) ==# 'run'
        call job_stop(s:job)
      endif
    catch
    endtry
    let s:job = v:null
  endif
endfunction

function! s:find_cargo_root(dir) abort
  let l:dir = a:dir
  while l:dir !=# fnamemodify(l:dir, ':h')
    if filereadable(l:dir . '/Cargo.toml')
      return l:dir
    endif
    let l:dir = fnamemodify(l:dir, ':h')
  endwhile
  return ''
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
