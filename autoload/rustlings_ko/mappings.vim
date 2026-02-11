" rustlings_ko/mappings.vim - Korean translation mappings for Rust compiler messages
" Ported from rustlings-ko.nvim to classic Vim 8.2+
"
" Provides four lazy-loaded data sources and a lookup function:
"   rustlings_ko#mappings#lookup(message)         - main lookup entry point
"   rustlings_ko#mappings#get_error_codes()       - dict of E-codes -> Korean
"   rustlings_ko#mappings#get_patterns()           - list of regex pattern dicts
"   rustlings_ko#mappings#get_warnings()           - list of warning pattern dicts
"   rustlings_ko#mappings#get_hints()              - list of hint pattern dicts
"
" Maintainer: rustlings-ko contributors
" License: MIT

let s:save_cpo = &cpo
set cpo&vim

" ---------------------------------------------------------------------------
" Script-local cache variables (lazy init)
" ---------------------------------------------------------------------------
let s:error_codes = {}
let s:patterns = []
let s:warnings = []
let s:hints = []
let s:error_codes_loaded = 0
let s:patterns_loaded = 0
let s:warnings_loaded = 0
let s:hints_loaded = 0

" ---------------------------------------------------------------------------
" Main lookup function
" ---------------------------------------------------------------------------

" Attempt to translate {message} using error codes, patterns, warnings, hints.
" Returns the Korean translation string, or v:null if no match found.
function! rustlings_ko#mappings#lookup(message) abort
  if a:message ==# ''
    return v:null
  endif

  " 1. Try error code lookup (e.g. "error[E0308]: mismatched types")
  let l:code = s:extract_error_code(a:message)
  if l:code !=# ''
    let l:codes = rustlings_ko#mappings#get_error_codes()
    if has_key(l:codes, l:code)
      return l:codes[l:code]
    endif
  endif

  " 2. Try pattern matching
  let l:result = s:try_pattern_list(rustlings_ko#mappings#get_patterns(), a:message)
  if l:result isnot v:null
    return l:result
  endif

  " 3. Try warning patterns
  let l:result = s:try_pattern_list(rustlings_ko#mappings#get_warnings(), a:message)
  if l:result isnot v:null
    return l:result
  endif

  " 4. Try hint patterns
  let l:result = s:try_pattern_list(rustlings_ko#mappings#get_hints(), a:message)
  if l:result isnot v:null
    return l:result
  endif

  return v:null
endfunction

" ---------------------------------------------------------------------------
" Internal helpers
" ---------------------------------------------------------------------------

" Extract an error code like 'E0308' from a message.
function! s:extract_error_code(message) abort
  let l:m = matchlist(a:message, '\v\[?(E\d{4})\]?')
  if !empty(l:m)
    return l:m[1]
  endif
  return ''
endfunction

" Try matching a message against a list of pattern dicts.
" Each dict has 'pattern' (Vim regex) and 'translation' (Korean with %1/%2).
" Returns the translated string, or v:null if no match.
function! s:try_pattern_list(patterns, message) abort
  for l:entry in a:patterns
    let l:m = matchlist(a:message, l:entry.pattern)
    if !empty(l:m)
      let l:result = l:entry.translation
      if l:m[1] !=# ''
        let l:result = substitute(l:result, '%1', l:m[1], 'g')
      endif
      if len(l:m) > 2 && l:m[2] !=# ''
        let l:result = substitute(l:result, '%2', l:m[2], 'g')
      endif
      if len(l:m) > 3 && l:m[3] !=# ''
        let l:result = substitute(l:result, '%3', l:m[3], 'g')
      endif
      return l:result
    endif
  endfor
  return v:null
endfunction

" ===========================================================================
" Error Codes (160+ entries)
" ===========================================================================
function! rustlings_ko#mappings#get_error_codes() abort
  if s:error_codes_loaded
    return s:error_codes
  endif

  let s:error_codes = {
        \ 'E0001': '패턴에 도달할 수 없습니다',
        \ 'E0002': '패턴 매칭에서 빈 범위입니다',
        \ 'E0004': '패턴 매칭이 완전하지 않습니다',
        \ 'E0005': '반박 가능한 패턴입니다',
        \ 'E0007': '바인딩 패턴으로 이동할 수 없습니다',
        \ 'E0008': 'by-move 바인딩과 by-ref 바인딩을 동시에 사용할 수 없습니다',
        \ 'E0009': 'by-move 바인딩과 by-ref 바인딩을 동시에 사용할 수 없습니다',
        \ 'E0010': '상수에서 할당할 수 없습니다',
        \ 'E0013': '상수에서 정적 변수를 참조할 수 없습니다',
        \ 'E0014': '상수에서 소멸자를 사용할 수 없습니다',
        \ 'E0015': '상수가 아닌 함수 호출은 상수에서 사용할 수 없습니다',
        \ 'E0023': '패턴에서 필드 수가 일치하지 않습니다',
        \ 'E0025': '필드가 이미 바인딩되었습니다',
        \ 'E0026': '존재하지 않는 필드를 사용했습니다',
        \ 'E0027': '패턴에서 일부 필드가 누락되었습니다',
        \ 'E0029': '범위 패턴에 사용할 수 없는 타입입니다',
        \ 'E0030': '범위의 시작이 끝보다 큽니다',
        \ 'E0031': '값이 너무 큽니다',
        \ 'E0032': '필드가 아닌 것에 필드 패턴을 사용할 수 없습니다',
        \ 'E0033': '크기를 알 수 없는 타입입니다',
        \ 'E0034': '메서드가 모호합니다',
        \ 'E0038': '트레이트를 객체로 사용할 수 없습니다',
        \ 'E0040': '소멸자를 명시적으로 호출할 수 없습니다',
        \ 'E0044': '외부 함수에 타입 매개변수를 사용할 수 없습니다',
        \ 'E0046': '트레이트 구현에서 항목이 누락되었습니다',
        \ 'E0050': '구현된 메서드의 매개변수 수가 다릅니다',
        \ 'E0053': '구현된 메서드의 매개변수 타입이 다릅니다',
        \ 'E0054': '캐스팅할 수 없는 타입입니다',
        \ 'E0055': '강제 변환 횟수가 한도를 초과했습니다',
        \ 'E0057': '클로저에 전달된 인수의 수가 잘못되었습니다',
        \ 'E0060': '함수에 전달된 인수가 부족합니다',
        \ 'E0061': '함수에 전달된 인수의 수가 잘못되었습니다',
        \ 'E0063': '구조체 초기화에서 필드가 누락되었습니다',
        \ 'E0106': '수명 매개변수가 누락되었습니다',
        \ 'E0107': '제네릭 인수의 수가 잘못되었습니다',
        \ 'E0110': '수명 매개변수가 허용되지 않습니다',
        \ 'E0119': '충돌하는 트레이트 구현이 있습니다',
        \ 'E0120': 'Drop 트레이트를 명시적으로 구현할 수 없습니다',
        \ 'E0133': 'unsafe 블록이 필요합니다',
        \ 'E0152': 'lang 항목이 중복 정의되었습니다',
        \ 'E0154': '이름이 두 번 이상 가져와졌습니다',
        \ 'E0158': '참조 불가능한 패턴에서 상수를 사용할 수 없습니다',
        \ 'E0161': '크기를 알 수 없는 타입의 값을 이동할 수 없습니다',
        \ 'E0162': '반박 불가능한 if-let 패턴입니다',
        \ 'E0164': '함수가 아닌 항목에 함수 스타일 패턴을 사용할 수 없습니다',
        \ 'E0165': '반박 불가능한 while-let 패턴입니다',
        \ 'E0170': '패턴 바인딩이 열거형 배리언트를 가립니다',
        \ 'E0178': '연산자 우선순위에 의한 모호한 바운드입니다',
        \ 'E0184': 'Copy 트레이트 구현이 유효하지 않습니다',
        \ 'E0185': '트레이트에는 없는 &self 매개변수입니다',
        \ 'E0186': '트레이트에 있는 &self 매개변수가 없습니다',
        \ 'E0191': '관련 타입의 값이 지정되지 않았습니다',
        \ 'E0195': '트레이트 선언과 수명 매개변수가 다릅니다',
        \ 'E0199': '긍정적 트레이트 구현의 안전성이 맞지 않습니다',
        \ 'E0200': '부정적 트레이트 구현의 안전성이 맞지 않습니다',
        \ 'E0220': '관련 타입을 찾을 수 없습니다',
        \ 'E0221': '관련 타입이 모호합니다',
        \ 'E0223': '관련 타입을 모호하게 사용했습니다',
        \ 'E0225': '한 개의 non-auto 트레이트만 객체 타입에 사용할 수 있습니다',
        \ 'E0228': '관련 타입 바운드에 명시적 수명이 필요합니다',
        \ 'E0252': '이름이 이미 가져와져 있습니다',
        \ 'E0253': '외부에 정의되지 않은 값을 가져올 수 없습니다',
        \ 'E0254': '이미 정의된 extern crate와 충돌합니다',
        \ 'E0255': '이미 가져온 이름과 충돌합니다',
        \ 'E0259': 'extern crate 이름이 충돌합니다',
        \ 'E0260': '이름이 외부 크레이트와 충돌합니다',
        \ 'E0261': '선언되지 않은 수명을 사용했습니다',
        \ 'E0262': '잘못된 수명 매개변수 이름입니다',
        \ 'E0263': '수명 이름이 중복 선언되었습니다',
        \ 'E0267': '루프 밖에서 `break`를 사용할 수 없습니다',
        \ 'E0268': '루프 밖에서 `continue`를 사용할 수 없습니다',
        \ 'E0271': '관련 타입의 불일치',
        \ 'E0275': '트레이트 해결 중 오버플로가 발생했습니다',
        \ 'E0276': '트레이트 메서드의 where 절을 만족하지 않습니다',
        \ 'E0277': '트레이트 바운드가 충족되지 않았습니다',
        \ 'E0282': '타입 어노테이션이 필요합니다',
        \ 'E0283': '타입이 모호합니다',
        \ 'E0284': '관련 타입을 추론할 수 없습니다',
        \ 'E0301': 'match 가드에서 가변 참조를 사용할 수 없습니다',
        \ 'E0302': 'match 가드에서 값을 할당할 수 없습니다',
        \ 'E0303': 'match 가드에서 바인딩 모드가 일치하지 않습니다',
        \ 'E0308': '타입 불일치',
        \ 'E0309': '타입 매개변수의 수명 제약 조건 불충족',
        \ 'E0310': "'static 수명 제약 조건 불충족",
        \ 'E0312': '참조의 수명이 충분하지 않습니다',
        \ 'E0317': 'if/else 분기의 타입이 일치하지 않습니다',
        \ 'E0326': '관련 타입의 값이 예상 타입과 다릅니다',
        \ 'E0329': '관련 타입에 접근할 수 없습니다',
        \ 'E0336': '정적 수명이 아닙니다',
        \ 'E0364': '비공개 항목을 재내보내기할 수 없습니다',
        \ 'E0365': '비공개 모듈을 재내보내기할 수 없습니다',
        \ 'E0368': '해당 타입에 이 이항 연산자를 적용할 수 없습니다',
        \ 'E0369': '해당 타입에 이항 연산자를 적용할 수 없습니다',
        \ 'E0370': '열거형 판별자 값이 너무 큽니다',
        \ 'E0373': '클로저가 빌린 값보다 오래 살 수 있습니다',
        \ 'E0374': '빌려온 내용을 클로저 밖으로 이동할 수 없습니다',
        \ 'E0378': 'DispatchFromDyn 구현이 유효하지 않습니다',
        \ 'E0379': '트레이트의 const 함수는 허용되지 않습니다',
        \ 'E0380': 'auto 트레이트에 메서드나 관련 항목을 정의할 수 없습니다',
        \ 'E0382': '이동된 값을 사용했습니다',
        \ 'E0383': '부분적으로 이동된 값을 사용했습니다',
        \ 'E0384': '불변 변수에 재할당할 수 없습니다',
        \ 'E0390': '기본 타입에 대한 메서드 구현이 허용되지 않습니다',
        \ 'E0391': '순환 의존성이 감지되었습니다',
        \ 'E0392': '사용되지 않는 타입 매개변수입니다',
        \ 'E0393': '기본 타입 매개변수를 추론할 수 없습니다',
        \ 'E0398': '타입 매개변수가 너무 많습니다',
        \ 'E0399': '트레이트 구현에 불필요한 항목이 있습니다',
        \ 'E0401': '외부 함수의 타입 매개변수를 사용할 수 없습니다',
        \ 'E0403': '이름이 이미 타입 매개변수로 사용되고 있습니다',
        \ 'E0404': '타입이 아닌 것을 타입으로 사용했습니다',
        \ 'E0405': '트레이트가 아닌 것을 트레이트로 사용했습니다',
        \ 'E0407': '트레이트에 없는 메서드를 구현했습니다',
        \ 'E0408': '패턴의 모든 대안에 바인딩이 없습니다',
        \ 'E0409': '패턴 대안에서 바인딩 모드가 일치하지 않습니다',
        \ 'E0411': '`Self`를 이 컨텍스트에서 사용할 수 없습니다',
        \ 'E0412': '타입을 찾을 수 없습니다',
        \ 'E0415': '함수 매개변수 이름이 중복됩니다',
        \ 'E0416': '패턴에서 식별자가 두 번 이상 바인딩되었습니다',
        \ 'E0422': '모듈을 찾을 수 없습니다',
        \ 'E0423': '예상치 못한 항목 종류입니다',
        \ 'E0424': '`self`가 없는 곳에서 `self`를 사용했습니다',
        \ 'E0425': '이름을 찾을 수 없습니다',
        \ 'E0426': '매크로에서 사용할 수 없는 이름입니다',
        \ 'E0428': '이름이 이미 정의되어 있습니다',
        \ 'E0430': '`self`를 이 위치에서 가져올 수 없습니다',
        \ 'E0431': '잘못된 `self` 가져오기입니다',
        \ 'E0432': '가져오기를 해결할 수 없습니다',
        \ 'E0433': '크레이트나 모듈을 찾을 수 없습니다',
        \ 'E0434': '외부 함수의 변수를 사용할 수 없습니다',
        \ 'E0435': '상수가 아닌 값을 상수 컨텍스트에서 사용할 수 없습니다',
        \ 'E0436': '함수형 구조체의 가시성이 일치하지 않습니다',
        \ 'E0437': '트레이트에 없는 타입을 구현했습니다',
        \ 'E0438': '트레이트에 없는 상수를 구현했습니다',
        \ 'E0449': '불필요한 가시성 지정자입니다',
        \ 'E0451': '비공개 필드에 접근할 수 없습니다',
        \ 'E0453': '허용되지 않은 lint를 사용했습니다',
        \ 'E0458': '연결할 라이브러리 이름이 지정되지 않았습니다',
        \ 'E0463': '크레이트를 찾을 수 없습니다',
        \ 'E0466': '매크로 가져오기가 잘못되었습니다',
        \ 'E0468': '비 루트 모듈에서 매크로를 내보낼 수 없습니다',
        \ 'E0477': '수명 바운드가 충족되지 않았습니다',
        \ 'E0478': '수명 바운드가 충족되지 않았습니다',
        \ 'E0491': '참조의 수명이 충족되지 않았습니다',
        \ 'E0492': '상수에서 interior mutability를 사용할 수 없습니다',
        \ 'E0493': '상수에서 소멸자를 호출하는 값을 사용할 수 없습니다',
        \ 'E0495': '함수의 수명 요구사항을 추론할 수 없습니다',
        \ 'E0496': '수명 이름이 이미 사용 중입니다',
        \ 'E0497': '안정화되지 않은 기능을 사용했습니다',
        \ 'E0499': '가변 참조를 동시에 두 개 이상 만들 수 없습니다',
        \ 'E0502': '불변 참조가 있는 동안 가변 참조를 만들 수 없습니다',
        \ 'E0503': '빌린 값을 사용할 수 없습니다',
        \ 'E0505': '빌린 값을 이동할 수 없습니다',
        \ 'E0506': '빌린 값에 재할당할 수 없습니다',
        \ 'E0507': '공유 참조 뒤의 값을 이동할 수 없습니다',
        \ 'E0508': '인덱싱된 내용을 이동할 수 없습니다',
        \ 'E0509': 'Drop을 구현한 타입의 필드를 이동할 수 없습니다',
        \ 'E0515': '함수에서 로컬 변수의 참조를 반환할 수 없습니다',
        \ 'E0516': '`typeof`는 예약되었지만 구현되지 않았습니다',
        \ 'E0517': '잘못된 repr 속성입니다',
        \ 'E0518': '#[inline] 속성을 사용할 수 없는 위치입니다',
        \ 'E0520': '트레이트에 없는 항목에 대한 특수화입니다',
        \ 'E0521': '빌린 데이터가 클로저 밖으로 나갈 수 없습니다',
        \ 'E0525': '클로저가 `Fn` 트레이트를 구현하지 않습니다',
        \ 'E0527': '패턴에 슬라이스 요소 수가 일치하지 않습니다',
        \ 'E0528': '슬라이스 패턴에 요소가 부족합니다',
        \ 'E0529': '슬라이스가 아닌 타입에 슬라이스 패턴을 사용했습니다',
        \ 'E0530': '바인딩이 기존 이름을 가립니다',
        \ 'E0531': '알 수 없는 경로를 사용했습니다',
        \ 'E0532': '구조체나 열거형 배리언트가 예상되었습니다',
        \ 'E0533': '잘못된 항목 종류입니다',
        \ 'E0534': '속성에 인수가 너무 많습니다',
        \ 'E0535': '알 수 없는 인수입니다',
        \ 'E0536': '속성에 인수가 필요합니다',
        \ 'E0537': '알 수 없는 메타 항목입니다',
        \ 'E0559': '열거형 배리언트에 해당 필드가 없습니다',
        \ 'E0560': '구조체에 해당 필드가 없습니다',
        \ 'E0562': 'impl Trait를 이 위치에서 사용할 수 없습니다',
        \ 'E0574': '모듈이나 타입이 예상되었습니다',
        \ 'E0582': '수명이 관련 항목에서 사용되지 않았습니다',
        \ 'E0583': '파일을 찾을 수 없습니다',
        \ 'E0587': 'packed와 align repr을 동시에 사용할 수 없습니다',
        \ 'E0588': 'packed 구조체에서 정렬이 맞지 않는 필드를 사용할 수 없습니다',
        \ 'E0592': '동일한 이름의 메서드가 여러 개 존재합니다',
        \ 'E0593': '클로저/함수의 인수 수가 일치하지 않습니다',
        \ 'E0596': '불변 항목에 가변 참조를 만들 수 없습니다',
        \ 'E0597': '값이 충분히 오래 살지 못합니다',
        \ 'E0599': '해당 타입에 메서드를 찾을 수 없습니다',
        \ 'E0600': '단항 부정 연산자를 적용할 수 없습니다',
        \ 'E0601': '`main` 함수를 찾을 수 없습니다',
        \ 'E0603': '비공개 항목에 접근할 수 없습니다',
        \ 'E0604': '기본형으로만 캐스팅할 수 있습니다',
        \ 'E0605': '이 타입으로 캐스팅할 수 없습니다',
        \ 'E0606': '이 as 표현식으로 캐스팅할 수 없습니다',
        \ 'E0607': '얇은 포인터로 캐스팅할 수 없습니다',
        \ 'E0608': '인덱싱할 수 없는 타입입니다',
        \ 'E0609': '해당 필드가 없습니다',
        \ 'E0610': '역참조할 수 없는 타입입니다',
        \ 'E0614': '역참조할 수 없는 타입입니다',
        \ 'E0615': '메서드를 필드처럼 사용했습니다',
        \ 'E0616': '비공개 필드에 접근할 수 없습니다',
        \ 'E0617': '외부 함수에 잘못된 타입의 인수를 전달했습니다',
        \ 'E0618': '함수가 아닌 것을 호출하려 했습니다',
        \ 'E0620': '크기를 알 수 없는 타입을 캐스팅할 수 없습니다',
        \ 'E0621': '수명이 일치하지 않습니다',
        \ 'E0622': '내장 함수는 항목이 아닙니다',
        \ 'E0623': '수명이 일치하지 않습니다',
        \ 'E0624': '비공개 메서드에 접근할 수 없습니다',
        \ 'E0625': '너무 많은 열거형 배리언트에 매칭했습니다',
        \ 'E0626': '제너레이터/async 함수에서 빌린 값을 yield할 수 없습니다',
        \ 'E0627': 'yield 표현식이 잘못된 위치에 있습니다',
        \ 'E0628': '제너레이터에 인수를 전달할 수 없습니다',
        \ 'E0631': '클로저/함수의 인수 타입이 일치하지 않습니다',
        \ 'E0632': 'union 패턴에서 필드를 하나만 지정해야 합니다',
        \ 'E0633': '잘못된 `unwind` 속성입니다',
        \ 'E0634': '타입이 너무 큽니다',
        \ 'E0635': '알 수 없는 기능 이름입니다',
        \ 'E0636': '기능이 중복 정의되었습니다',
        \ 'E0637': "`'_`는 이 위치에서 사용할 수 없습니다",
        \ 'E0638': 'non-exhaustive 열거형에 대해 패턴이 완전하지 않습니다',
        \ 'E0639': '비공개 타입에 접근할 수 없습니다',
        \ 'E0642': '패턴에서 trait object를 사용할 수 없습니다',
        \ 'E0643': '수명 바운드 위치에서 impl Trait를 사용할 수 없습니다',
        \ 'E0646': '`main` 함수에 `#[start]`를 사용할 수 없습니다',
        \ 'E0647': '`start` 함수가 여러 번 정의되었습니다',
        \ 'E0648': '`export_name` 속성이 잘못되었습니다',
        \ 'E0658': '안정화되지 않은 기능을 사용했습니다',
        \ 'E0659': '이름이 모호합니다',
        \ 'E0689': '메서드 호출에서 타입이 모호합니다',
        \ 'E0692': 'transparent repr에 여러 필드가 있습니다',
        \ 'E0693': '잘못된 정렬 값입니다',
        \ 'E0695': '레이블 없는 블록에서 break할 수 없습니다',
        \ 'E0696': '블록에서 continue를 사용할 수 없습니다',
        \ 'E0728': '`await`는 `async` 함수나 블록에서만 사용할 수 있습니다',
        \ 'E0733': '재귀적 `async fn`은 허용되지 않습니다',
        \ 'E0734': '잘못된 `#[stable]` 속성입니다',
        \ }

  let s:error_codes_loaded = 1
  return s:error_codes
endfunction

" ===========================================================================
" Patterns (46 entries)
"
" Each entry: {'pattern': <vim regex>, 'translation': <Korean with %1/%2>}
" ===========================================================================
function! rustlings_ko#mappings#get_patterns() abort
  if s:patterns_loaded
    return s:patterns
  endif

  let s:patterns = [
        \ {'pattern': 'expected `\([^`]*\)`, found `\([^`]*\)`',
        \  'translation': '`%1` 타입이 예상되었지만 `%2` 타입이 발견되었습니다'},
        \ {'pattern': 'expected \(.\+\) found \(.\+\)',
        \  'translation': '%1 예상되었지만 %2 발견되었습니다'},
        \ {'pattern': 'mismatched types',
        \  'translation': '타입이 일치하지 않습니다'},
        \ {'pattern': 'the trait bound `\([^`]*\)`\s\+is not satisfied',
        \  'translation': '트레이트 바운드 `%1`이(가) 충족되지 않았습니다'},
        \ {'pattern': 'the trait `\([^`]*\)`\s\+is not implemented for `\([^`]*\)`',
        \  'translation': '`%2` 타입에 대해 트레이트 `%1`이(가) 구현되지 않았습니다'},
        \ {'pattern': "doesn't implement `\\([^`]*\\)`",
        \  'translation': '`%1`을(를) 구현하지 않습니다'},
        \ {'pattern': 'cannot borrow `\([^`]*\)`\s\+as mutable, as it is not declared as mutable',
        \  'translation': '`%1`을(를) 가변으로 빌릴 수 없습니다 (mut로 선언되지 않았습니다)'},
        \ {'pattern': 'cannot borrow `\([^`]*\)`\s\+as mutable more than once at a time',
        \  'translation': '`%1`에 대한 가변 참조를 동시에 두 개 이상 만들 수 없습니다'},
        \ {'pattern': 'cannot borrow `\([^`]*\)`\s\+as immutable because it is also borrowed as mutable',
        \  'translation': '`%1`이(가) 가변으로 빌려진 동안 불변으로 빌릴 수 없습니다'},
        \ {'pattern': 'cannot move out of `\([^`]*\)`',
        \  'translation': '`%1`에서 값을 이동할 수 없습니다'},
        \ {'pattern': 'cannot move out of borrowed content',
        \  'translation': '빌린 내용에서 값을 이동할 수 없습니다'},
        \ {'pattern': 'use of moved value: `\([^`]*\)`',
        \  'translation': '이동된 값을 사용했습니다: `%1`'},
        \ {'pattern': 'value used here after move',
        \  'translation': '이동 후 여기에서 값이 사용되었습니다'},
        \ {'pattern': 'borrow of moved value: `\([^`]*\)`',
        \  'translation': '이동된 값을 빌렸습니다: `%1`'},
        \ {'pattern': '`\([^`]*\)`\s\+does not live long enough',
        \  'translation': '`%1`의 수명이 충분하지 않습니다'},
        \ {'pattern': 'lifetime `\([^`]*\)`\s\+does not live long enough',
        \  'translation': '수명 `%1`이(가) 충분히 길지 않습니다'},
        \ {'pattern': 'missing lifetime specifier',
        \  'translation': '수명 지정자가 누락되었습니다'},
        \ {'pattern': 'cannot find value `\([^`]*\)`\s\+in this scope',
        \  'translation': '이 스코프에서 값 `%1`을(를) 찾을 수 없습니다'},
        \ {'pattern': 'cannot find type `\([^`]*\)`\s\+in this scope',
        \  'translation': '이 스코프에서 타입 `%1`을(를) 찾을 수 없습니다'},
        \ {'pattern': 'cannot find trait `\([^`]*\)`\s\+in this scope',
        \  'translation': '이 스코프에서 트레이트 `%1`을(를) 찾을 수 없습니다'},
        \ {'pattern': 'cannot find macro `\([^`]*\)`\s\+in this scope',
        \  'translation': '이 스코프에서 매크로 `%1`을(를) 찾을 수 없습니다'},
        \ {'pattern': 'not found in this scope',
        \  'translation': '이 스코프에서 찾을 수 없습니다'},
        \ {'pattern': 'this function takes \(\d\+\) arguments\= but \(\d\+\) arguments\= were supplied',
        \  'translation': '이 함수는 %1개의 인수를 받지만 %2개의 인수가 전달되었습니다'},
        \ {'pattern': 'this function takes \(\d\+\) arguments\= but \(\d\+\) arguments\= was supplied',
        \  'translation': '이 함수는 %1개의 인수를 받지만 %2개의 인수가 전달되었습니다'},
        \ {'pattern': 'no method named `\([^`]*\)`\s\+found for \(.\+\) in the current scope',
        \  'translation': '현재 스코프에서 %2에 대한 메서드 `%1`을(를) 찾을 수 없습니다'},
        \ {'pattern': 'no field `\([^`]*\)`\s\+on type `\([^`]*\)`',
        \  'translation': '타입 `%2`에 필드 `%1`이(가) 없습니다'},
        \ {'pattern': 'unused variable: `\([^`]*\)`',
        \  'translation': '사용되지 않는 변수: `%1`'},
        \ {'pattern': 'unused import: `\([^`]*\)`',
        \  'translation': '사용되지 않는 가져오기: `%1`'},
        \ {'pattern': 'unused mut',
        \  'translation': '불필요한 mut 지정자'},
        \ {'pattern': 'variable does not need to be mutable',
        \  'translation': '변수를 가변으로 지정할 필요가 없습니다'},
        \ {'pattern': 'cannot assign to `\([^`]*\)`, as it is not declared as mutable',
        \  'translation': '`%1`에 할당할 수 없습니다 (mut로 선언되지 않았습니다)'},
        \ {'pattern': 'cannot assign twice to immutable variable `\([^`]*\)`',
        \  'translation': '불변 변수 `%1`에 두 번 할당할 수 없습니다'},
        \ {'pattern': 'cannot assign to immutable',
        \  'translation': '불변 항목에 할당할 수 없습니다'},
        \ {'pattern': 'call to unsafe function is unsafe and requires unsafe',
        \  'translation': '안전하지 않은 함수 호출이며 unsafe 블록이 필요합니다'},
        \ {'pattern': 'this operation is unsafe and requires an unsafe',
        \  'translation': '이 연산은 안전하지 않으며 unsafe 블록이 필요합니다'},
        \ {'pattern': 'unresolved import `\([^`]*\)`',
        \  'translation': '해결되지 않은 가져오기: `%1`'},
        \ {'pattern': 'could not find `\([^`]*\)`\s\+in `\([^`]*\)`',
        \  'translation': '`%2`에서 `%1`을(를) 찾을 수 없습니다'},
        \ {'pattern': 'failed to resolve: use of undeclared',
        \  'translation': '선언되지 않은 항목을 사용하여 해결할 수 없습니다'},
        \ {'pattern': 'non-exhaustive patterns: `\([^`]*\)`\s\+not covered',
        \  'translation': '완전하지 않은 패턴: `%1`이(가) 처리되지 않았습니다'},
        \ {'pattern': 'non-exhaustive patterns',
        \  'translation': '완전하지 않은 패턴입니다'},
        \ {'pattern': 'type `\([^`]*\)`\s\+cannot be dereferenced',
        \  'translation': '타입 `%1`을(를) 역참조할 수 없습니다'},
        \ {'pattern': 'the size for values of type `\([^`]*\)`\s\+cannot be known at compilation time',
        \  'translation': '컴파일 시점에 타입 `%1`의 크기를 알 수 없습니다'},
        \ {'pattern': "doesn't have a size known at compile-time",
        \  'translation': '컴파일 시점에 크기를 알 수 없습니다'},
        \ {'pattern': 'match arms have incompatible types',
        \  'translation': 'match 갈래의 타입이 호환되지 않습니다'},
        \ {'pattern': 'if and else have incompatible types',
        \  'translation': 'if와 else의 타입이 호환되지 않습니다'},
        \ {'pattern': 'implicitly returns `()`\s\+as its body has no tail or `return` expression',
        \  'translation': '함수 본문에 꼬리 표현식이나 `return`이 없어 암묵적으로 `()`를 반환합니다'},
        \ ]

  let s:patterns_loaded = 1
  return s:patterns
endfunction

" ===========================================================================
" Warnings (10 entries)
" ===========================================================================
function! rustlings_ko#mappings#get_warnings() abort
  if s:warnings_loaded
    return s:warnings
  endif

  let s:warnings = [
        \ {'pattern': 'unused variable',
        \  'translation': '사용되지 않는 변수'},
        \ {'pattern': 'unused import',
        \  'translation': '사용되지 않는 가져오기'},
        \ {'pattern': 'unused mut',
        \  'translation': '불필요한 mut 지정자'},
        \ {'pattern': 'dead_code',
        \  'translation': '사용되지 않는 코드'},
        \ {'pattern': 'unreachable_code',
        \  'translation': '도달할 수 없는 코드'},
        \ {'pattern': 'deprecated',
        \  'translation': '더 이상 사용되지 않습니다 (deprecated)'},
        \ {'pattern': 'value assigned .\+ is never read',
        \  'translation': '할당된 값이 읽히지 않습니다'},
        \ {'pattern': 'unused `#\[must_use\]`',
        \  'translation': '사용해야 하는 값이 사용되지 않았습니다 (#[must_use])'},
        \ {'pattern': 'irrefutable `if let` pattern',
        \  'translation': '반박 불가능한 `if let` 패턴입니다'},
        \ {'pattern': 'denote infinite loops with `loop',
        \  'translation': '무한 루프는 `loop`로 표현하세요'},
        \ ]

  let s:warnings_loaded = 1
  return s:warnings
endfunction

" ===========================================================================
" Hints (15 entries)
" ===========================================================================
function! rustlings_ko#mappings#get_hints() abort
  if s:hints_loaded
    return s:hints
  endif

  let s:hints = [
        \ {'pattern': 'consider borrowing here',
        \  'translation': '여기에서 빌림(&)을 사용해 보세요'},
        \ {'pattern': 'consider using a `let` binding',
        \  'translation': '`let` 바인딩을 사용해 보세요'},
        \ {'pattern': 'help: consider using',
        \  'translation': '도움말: 다음을 사용해 보세요'},
        \ {'pattern': 'did you mean `\([^`]*\)`?',
        \  'translation': '`%1`을(를) 의미하셨나요?'},
        \ {'pattern': 'help: use `mut`',
        \  'translation': '도움말: `mut`를 사용하세요'},
        \ {'pattern': 'consider adding a `;`',
        \  'translation': '`;`를 추가해 보세요'},
        \ {'pattern': 'perhaps a semicolon is missing',
        \  'translation': '세미콜론이 빠진 것 같습니다'},
        \ {'pattern': 'consider changing this to be mutable',
        \  'translation': '이것을 가변(mut)으로 변경해 보세요'},
        \ {'pattern': 'to force the closure to take ownership',
        \  'translation': '클로저가 소유권을 가지도록 하세요'},
        \ {'pattern': 'consider using `clone`',
        \  'translation': '`clone`을 사용해 보세요'},
        \ {'pattern': 'consider adding an explicit lifetime bound',
        \  'translation': '명시적 수명 바운드를 추가해 보세요'},
        \ {'pattern': 'consider restricting type parameter',
        \  'translation': '타입 매개변수에 제약을 추가해 보세요'},
        \ {'pattern': 'you can convert',
        \  'translation': '다음과 같이 변환할 수 있습니다'},
        \ {'pattern': 'try using a conversion method',
        \  'translation': '변환 메서드를 사용해 보세요'},
        \ {'pattern': 'if you meant to write a `str` literal',
        \  'translation': '`str` 리터럴을 작성하려면'},
        \ ]

  let s:hints_loaded = 1
  return s:hints
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
