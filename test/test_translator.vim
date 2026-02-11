" test/test_translator.vim - Test suite for rustlings-ko.vim
"
" Run with:  vim -u NONE -N --cmd 'source test/test_translator.vim' --cmd 'qa!'
"
" Maintainer: rustlings-ko contributors
" License: MIT

let s:tests_run = 0
let s:tests_passed = 0
let s:tests_failed = 0
let s:errors = []

" ---------------------------------------------------------------------------
" Test framework
" ---------------------------------------------------------------------------

function! s:assert(condition, description) abort
  let s:tests_run += 1
  if a:condition
    let s:tests_passed += 1
  else
    let s:tests_failed += 1
    call add(s:errors, 'FAIL: ' . a:description)
  endif
endfunction

function! s:assert_equal(expected, actual, description) abort
  let s:tests_run += 1
  if a:expected ==# a:actual
    let s:tests_passed += 1
  else
    let s:tests_failed += 1
    let l:msg = 'FAIL: ' . a:description
          \ . "\n  expected: " . string(a:expected)
          \ . "\n  actual:   " . string(a:actual)
    call add(s:errors, l:msg)
  endif
endfunction

function! s:assert_not_null(value, description) abort
  let s:tests_run += 1
  if a:value isnot v:null
    let s:tests_passed += 1
  else
    let s:tests_failed += 1
    call add(s:errors, 'FAIL: ' . a:description . ' (got v:null)')
  endif
endfunction

function! s:assert_null(value, description) abort
  let s:tests_run += 1
  if a:value is v:null
    let s:tests_passed += 1
  else
    let s:tests_failed += 1
    call add(s:errors, 'FAIL: ' . a:description . ' (expected v:null, got ' . string(a:value) . ')')
  endif
endfunction

" ---------------------------------------------------------------------------
" Setup: load plugin without FileType autocmd
" ---------------------------------------------------------------------------

" Set config defaults
let g:rustlings_ko_enabled = 1
let g:rustlings_ko_mode = 'mapping'
let g:rustlings_ko_show_original = 0
let g:rustlings_ko_cache_max_size = 500
let g:rustlings_ko_backend = 'quickfix'
let g:rustlings_ko_diagnostics_format = '%s'
let g:rustlings_ko_original_format = "\n[원문] %s"
let g:rustlings_ko_llm_provider = ''
let g:rustlings_ko_llm_api_key = ''

" Source the autoload files
runtime autoload/rustlings_ko/cache.vim
runtime autoload/rustlings_ko/mappings.vim
runtime autoload/rustlings_ko/translator.vim
runtime autoload/rustlings_ko.vim

" ---------------------------------------------------------------------------
" Test: Cache
" ---------------------------------------------------------------------------

function! s:test_cache() abort
  call rustlings_ko#cache#init(500)

  " Empty cache returns null
  call s:assert_null(rustlings_ko#cache#get('nonexistent'), 'cache miss returns null')

  " Set and get
  call rustlings_ko#cache#set('hello', 'world')
  call s:assert_equal('world', rustlings_ko#cache#get('hello'), 'cache set/get')

  " Size
  call s:assert_equal(1, rustlings_ko#cache#size(), 'cache size after one set')

  " Update existing key
  call rustlings_ko#cache#set('hello', 'updated')
  call s:assert_equal('updated', rustlings_ko#cache#get('hello'), 'cache update')
  call s:assert_equal(1, rustlings_ko#cache#size(), 'cache size after update (no duplicates)')

  " Clear
  call rustlings_ko#cache#clear()
  call s:assert_null(rustlings_ko#cache#get('hello'), 'cache clear')
  call s:assert_equal(0, rustlings_ko#cache#size(), 'cache size after clear')

  " LRU eviction
  call rustlings_ko#cache#init(3)
  call rustlings_ko#cache#set('a', '1')
  call rustlings_ko#cache#set('b', '2')
  call rustlings_ko#cache#set('c', '3')
  call s:assert_equal(3, rustlings_ko#cache#size(), 'cache size at max')
  call rustlings_ko#cache#set('d', '4')
  call s:assert_equal(3, rustlings_ko#cache#size(), 'cache size after eviction')
  call s:assert_null(rustlings_ko#cache#get('a'), 'LRU evicted oldest entry')
  call s:assert_equal('4', rustlings_ko#cache#get('d'), 'newest entry present')

  " Reset for other tests
  call rustlings_ko#cache#clear()
  call rustlings_ko#cache#init(500)
endfunction

" ---------------------------------------------------------------------------
" Test: Error code lookup
" ---------------------------------------------------------------------------

function! s:test_error_codes() abort
  let l:codes = rustlings_ko#mappings#get_error_codes()

  " Check some key error codes exist
  call s:assert(has_key(l:codes, 'E0308'), 'E0308 exists')
  call s:assert(has_key(l:codes, 'E0382'), 'E0382 exists')
  call s:assert(has_key(l:codes, 'E0277'), 'E0277 exists')
  call s:assert(has_key(l:codes, 'E0499'), 'E0499 exists')

  " Check Korean translation content
  call s:assert_equal('타입 불일치', l:codes['E0308'], 'E0308 translation')
  call s:assert_equal('이동된 값을 사용했습니다', l:codes['E0382'], 'E0382 translation')
endfunction

" ---------------------------------------------------------------------------
" Test: Error code extraction from messages
" ---------------------------------------------------------------------------

function! s:test_error_code_lookup() abort
  " Message with error code should be translated via lookup
  let l:result = rustlings_ko#mappings#lookup('error[E0308]: mismatched types')
  call s:assert_not_null(l:result, 'E0308 lookup found')
  call s:assert_equal('타입 불일치', l:result, 'E0308 lookup result')

  let l:result2 = rustlings_ko#mappings#lookup('error[E0382]: borrow of moved value')
  call s:assert_not_null(l:result2, 'E0382 lookup found')
  call s:assert_equal('이동된 값을 사용했습니다', l:result2, 'E0382 lookup result')
endfunction

" ---------------------------------------------------------------------------
" Test: Pattern matching
" ---------------------------------------------------------------------------

function! s:test_patterns() abort
  let l:patterns = rustlings_ko#mappings#get_patterns()
  call s:assert(len(l:patterns) >= 40, 'has 40+ patterns')

  " Test: mismatched types
  let l:result = rustlings_ko#mappings#lookup('mismatched types')
  call s:assert_not_null(l:result, 'mismatched types pattern found')
  call s:assert_equal('타입이 일치하지 않습니다', l:result, 'mismatched types translation')

  " Test: expected/found with capture groups
  let l:result2 = rustlings_ko#mappings#lookup('expected `i32`, found `String`')
  call s:assert_not_null(l:result2, 'expected/found pattern found')
  call s:assert_equal('`i32` 타입이 예상되었지만 `String` 타입이 발견되었습니다',
        \ l:result2, 'expected/found with captures')

  " Test: cannot borrow as mutable
  let l:result3 = rustlings_ko#mappings#lookup(
        \ 'cannot borrow `x` as mutable, as it is not declared as mutable')
  call s:assert_not_null(l:result3, 'cannot borrow mutable pattern found')

  " Test: unused variable
  let l:result4 = rustlings_ko#mappings#lookup('unused variable: `foo`')
  call s:assert_not_null(l:result4, 'unused variable pattern found')
  call s:assert_equal('사용되지 않는 변수: `foo`', l:result4, 'unused variable translation')

  " Test: cannot find value in scope
  let l:result5 = rustlings_ko#mappings#lookup('cannot find value `bar` in this scope')
  call s:assert_not_null(l:result5, 'cannot find value pattern found')
  call s:assert_equal('이 스코프에서 값 `bar`을(를) 찾을 수 없습니다',
        \ l:result5, 'cannot find value translation')

  " Test: no field on type
  let l:result6 = rustlings_ko#mappings#lookup('no field `name` on type `User`')
  call s:assert_not_null(l:result6, 'no field on type pattern found')
  call s:assert_equal('타입 `User`에 필드 `name`이(가) 없습니다',
        \ l:result6, 'no field on type translation')
endfunction

" ---------------------------------------------------------------------------
" Test: Warning patterns
" ---------------------------------------------------------------------------

function! s:test_warnings() abort
  let l:warnings = rustlings_ko#mappings#get_warnings()
  call s:assert(len(l:warnings) >= 10, 'has 10+ warnings')

  let l:result = rustlings_ko#mappings#lookup('unused variable')
  call s:assert_not_null(l:result, 'unused variable warning found')

  let l:result2 = rustlings_ko#mappings#lookup('dead_code')
  call s:assert_not_null(l:result2, 'dead_code warning found')
  call s:assert_equal('사용되지 않는 코드', l:result2, 'dead_code translation')
endfunction

" ---------------------------------------------------------------------------
" Test: Hint patterns
" ---------------------------------------------------------------------------

function! s:test_hints() abort
  let l:hints = rustlings_ko#mappings#get_hints()
  call s:assert(len(l:hints) >= 15, 'has 15+ hints')

  let l:result = rustlings_ko#mappings#lookup('consider borrowing here')
  call s:assert_not_null(l:result, 'consider borrowing hint found')
  call s:assert_equal('여기에서 빌림(&)을 사용해 보세요', l:result,
        \ 'consider borrowing translation')

  let l:result2 = rustlings_ko#mappings#lookup('did you mean `foo`?')
  call s:assert_not_null(l:result2, 'did you mean hint found')
  call s:assert_equal('`foo`을(를) 의미하셨나요?', l:result2,
        \ 'did you mean translation')
endfunction

" ---------------------------------------------------------------------------
" Test: Edge cases
" ---------------------------------------------------------------------------

function! s:test_edge_cases() abort
  " Empty message
  call s:assert_null(rustlings_ko#mappings#lookup(''), 'empty message returns null')

  " Unknown message
  call s:assert_null(rustlings_ko#mappings#lookup('some random text'),
        \ 'unknown message returns null')

  " translator#translate wraps mappings#lookup
  call s:assert_null(rustlings_ko#translator#translate(''),
        \ 'translator empty message returns null')

  let l:t = rustlings_ko#translator#translate('mismatched types')
  call s:assert_not_null(l:t, 'translator delegates to mappings')
endfunction

" ---------------------------------------------------------------------------
" Test: format_message
" ---------------------------------------------------------------------------

function! s:test_format_message() abort
  " Simple format (default)
  let g:rustlings_ko_show_original = 0
  let l:result = rustlings_ko#translator#format_message('타입 불일치', 'mismatched types')
  call s:assert_equal('타입 불일치', l:result, 'format without original')

  " With original
  let g:rustlings_ko_show_original = 1
  let l:result2 = rustlings_ko#translator#format_message('타입 불일치', 'mismatched types')
  call s:assert(l:result2 =~# '타입 불일치', 'format has translation')
  call s:assert(l:result2 =~# 'mismatched types', 'format has original')

  " Same translation as original (should not append)
  let l:result3 = rustlings_ko#translator#format_message('hello', 'hello')
  call s:assert_equal('hello', l:result3, 'same text: no original appended')

  " Reset
  let g:rustlings_ko_show_original = 0
endfunction

" ---------------------------------------------------------------------------
" Test: Main translate function
" ---------------------------------------------------------------------------

function! s:test_main_translate() abort
  " Enabled: should translate
  let g:rustlings_ko_enabled = 1
  call rustlings_ko#cache#clear()
  let l:result = rustlings_ko#translate('mismatched types')
  call s:assert_equal('타입이 일치하지 않습니다', l:result, 'main translate works')

  " Disabled: should return original
  let g:rustlings_ko_enabled = 0
  let l:result2 = rustlings_ko#translate('mismatched types')
  call s:assert_equal('mismatched types', l:result2, 'disabled returns original')

  " Re-enable
  let g:rustlings_ko_enabled = 1

  " Empty message
  let l:result3 = rustlings_ko#translate('')
  call s:assert_equal('', l:result3, 'empty message returns empty')

  " Cached result
  call rustlings_ko#cache#clear()
  call rustlings_ko#translate('mismatched types')
  let l:cached = rustlings_ko#cache#get('mismatched types')
  call s:assert_not_null(l:cached, 'translation cached after first call')
endfunction

" ---------------------------------------------------------------------------
" Run all tests
" ---------------------------------------------------------------------------

function! s:run_tests() abort
  echomsg '=== rustlings-ko.vim Test Suite ==='
  echomsg ''

  call s:test_cache()
  echomsg 'Cache tests done'

  call s:test_error_codes()
  echomsg 'Error code tests done'

  call s:test_error_code_lookup()
  echomsg 'Error code lookup tests done'

  call s:test_patterns()
  echomsg 'Pattern tests done'

  call s:test_warnings()
  echomsg 'Warning tests done'

  call s:test_hints()
  echomsg 'Hint tests done'

  call s:test_edge_cases()
  echomsg 'Edge case tests done'

  call s:test_format_message()
  echomsg 'Format message tests done'

  call s:test_main_translate()
  echomsg 'Main translate tests done'

  echomsg ''
  echomsg '=== Results ==='
  echomsg printf('Total: %d | Passed: %d | Failed: %d',
        \ s:tests_run, s:tests_passed, s:tests_failed)

  if s:tests_failed > 0
    echomsg ''
    echomsg '=== Failures ==='
    for l:err in s:errors
      echomsg l:err
    endfor
    cquit!
  else
    echomsg 'All tests passed!'
  endif
endfunction

call s:run_tests()
