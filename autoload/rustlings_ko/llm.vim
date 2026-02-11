" rustlings_ko/llm.vim - LLM fallback translation using Vim 8 job_start()
" Provides async translation via Anthropic Claude or OpenAI GPT APIs
" Requires: Vim 8.2+, curl in PATH
"
" Maintainer: rustlings-ko contributors
" License: MIT

let s:save_cpo = &cpo
set cpo&vim

" ---------------------------------------------------------------------------
" System prompt for LLM translation
" ---------------------------------------------------------------------------
let s:system_prompt = 'You are a Rust compiler error message translator. '
      \ . 'Translate the following Rust compiler error message to Korean. '
      \ . "Rules:\n"
      \ . "- Translate only the natural language parts\n"
      \ . "- Keep all code inside backticks (`) exactly as-is\n"
      \ . "- Keep all type names, function names, and variable names exactly as-is\n"
      \ . "- Use formal Korean style\n"
      \ . "- Be concise and accurate\n"
      \ . "- Return ONLY the translated message, nothing else"

" ---------------------------------------------------------------------------
" Rate limiting state
" ---------------------------------------------------------------------------
let s:last_request_time = 0
let s:min_interval = 1.0
let s:pending_jobs = {}

" ---------------------------------------------------------------------------
" Public API
" ---------------------------------------------------------------------------

" Translate a message asynchronously via LLM.
"
" {message}  - The English diagnostic message to translate.
" {Callback} - A Funcref called with the translated string on success.
function! rustlings_ko#llm#translate_async(message, Callback) abort
  " Guard: check mode
  let l:mode = get(g:, 'rustlings_ko_mode', 'mapping')
  if l:mode !=# 'llm'
    return
  endif

  " Guard: check API key
  let l:api_key = get(g:, 'rustlings_ko_llm_api_key', '')
  if empty(l:api_key)
    return
  endif

  " Guard: check provider
  let l:provider = get(g:, 'rustlings_ko_llm_provider', '')
  if l:provider !=# 'anthropic' && l:provider !=# 'openai'
    return
  endif

  " Guard: skip empty messages
  if empty(a:message)
    return
  endif

  " Guard: skip if identical request is already in-flight
  if has_key(s:pending_jobs, a:message)
    return
  endif

  " Rate limiting
  let l:now = reltime()
  if type(s:last_request_time) == type([])
    let l:elapsed = reltimefloat(reltime(s:last_request_time))
    if l:elapsed < s:min_interval
      return
    endif
  endif
  let s:last_request_time = reltime()

  " Build request
  let l:body = s:build_request_body(l:provider, a:message)
  let l:cmd = s:build_curl_cmd(l:provider, l:api_key, l:body)

  " Start async job
  let l:ctx = {
        \ 'message': a:message,
        \ 'provider': l:provider,
        \ 'callback': a:Callback,
        \ 'output': [],
        \ }

  let l:job = job_start(l:cmd, {
        \ 'out_cb': function('s:on_stdout', [l:ctx]),
        \ 'err_cb': function('s:on_stderr', [l:ctx]),
        \ 'exit_cb': function('s:on_exit', [l:ctx]),
        \ 'out_mode': 'raw',
        \ })

  if job_status(l:job) !=# 'fail'
    let s:pending_jobs[a:message] = l:job
  endif
endfunction

" Check whether LLM translation is properly configured.
function! rustlings_ko#llm#is_configured() abort
  let l:mode = get(g:, 'rustlings_ko_mode', 'mapping')
  if l:mode !=# 'llm'
    return 0
  endif
  let l:api_key = get(g:, 'rustlings_ko_llm_api_key', '')
  if empty(l:api_key)
    return 0
  endif
  let l:provider = get(g:, 'rustlings_ko_llm_provider', '')
  return l:provider ==# 'anthropic' || l:provider ==# 'openai'
endfunction

" Return the current provider name or empty string.
function! rustlings_ko#llm#provider() abort
  return get(g:, 'rustlings_ko_llm_provider', '')
endfunction

" ---------------------------------------------------------------------------
" Request body builders
" ---------------------------------------------------------------------------
function! s:build_request_body(provider, message) abort
  if a:provider ==# 'anthropic'
    return json_encode({
          \ 'model': 'claude-sonnet-4-5-20250929',
          \ 'max_tokens': 1024,
          \ 'system': s:system_prompt,
          \ 'messages': [{'role': 'user', 'content': a:message}],
          \ })
  else
    return json_encode({
          \ 'model': 'gpt-4o-mini',
          \ 'max_tokens': 1024,
          \ 'messages': [
          \   {'role': 'system', 'content': s:system_prompt},
          \   {'role': 'user', 'content': a:message},
          \ ],
          \ })
  endif
endfunction

" ---------------------------------------------------------------------------
" curl command builders
" ---------------------------------------------------------------------------
function! s:build_curl_cmd(provider, api_key, body) abort
  if a:provider ==# 'anthropic'
    return ['curl', '-s', '-X', 'POST',
          \ 'https://api.anthropic.com/v1/messages',
          \ '-H', 'Content-Type: application/json',
          \ '-H', 'x-api-key: ' . a:api_key,
          \ '-H', 'anthropic-version: 2023-06-01',
          \ '--max-time', '30',
          \ '-d', a:body]
  else
    return ['curl', '-s', '-X', 'POST',
          \ 'https://api.openai.com/v1/chat/completions',
          \ '-H', 'Content-Type: application/json',
          \ '-H', 'Authorization: Bearer ' . a:api_key,
          \ '--max-time', '30',
          \ '-d', a:body]
  endif
endfunction

" ---------------------------------------------------------------------------
" Job callbacks
" ---------------------------------------------------------------------------
function! s:on_stdout(ctx, channel, msg) abort
  call add(a:ctx.output, a:msg)
endfunction

function! s:on_stderr(ctx, channel, msg) abort
endfunction

function! s:on_exit(ctx, job, status) abort
  if has_key(s:pending_jobs, a:ctx.message)
    call remove(s:pending_jobs, a:ctx.message)
  endif

  if a:status != 0
    return
  endif

  let l:response_text = join(a:ctx.output, '')
  if empty(l:response_text)
    return
  endif

  let l:translated = s:parse_response(a:ctx.provider, l:response_text)

  if !empty(l:translated)
    call rustlings_ko#cache#set(a:ctx.message, l:translated)
    call a:ctx.callback(l:translated)
  endif
endfunction

" ---------------------------------------------------------------------------
" Response parsers
" ---------------------------------------------------------------------------
function! s:parse_response(provider, response_text) abort
  try
    let l:decoded = json_decode(a:response_text)
  catch
    return ''
  endtry

  if type(l:decoded) != type({})
    return ''
  endif

  if has_key(l:decoded, 'error')
    return ''
  endif

  if a:provider ==# 'anthropic'
    return s:parse_anthropic_response(l:decoded)
  else
    return s:parse_openai_response(l:decoded)
  endif
endfunction

function! s:parse_anthropic_response(decoded) abort
  if !has_key(a:decoded, 'content')
    return ''
  endif
  let l:content = a:decoded.content
  if type(l:content) != type([]) || empty(l:content)
    return ''
  endif
  let l:first = l:content[0]
  if type(l:first) != type({}) || !has_key(l:first, 'text')
    return ''
  endif
  let l:text = l:first.text
  if type(l:text) != type('')
    return ''
  endif
  return substitute(substitute(l:text, '^\s\+', '', ''), '\s\+$', '', '')
endfunction

function! s:parse_openai_response(decoded) abort
  if !has_key(a:decoded, 'choices')
    return ''
  endif
  let l:choices = a:decoded.choices
  if type(l:choices) != type([]) || empty(l:choices)
    return ''
  endif
  let l:first = l:choices[0]
  if type(l:first) != type({}) || !has_key(l:first, 'message')
    return ''
  endif
  let l:message = l:first.message
  if type(l:message) != type({}) || !has_key(l:message, 'content')
    return ''
  endif
  let l:text = l:message.content
  if type(l:text) != type('')
    return ''
  endif
  return substitute(substitute(l:text, '^\s\+', '', ''), '\s\+$', '', '')
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
