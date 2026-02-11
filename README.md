# rustlings-ko.vim

Rust 컴파일러 진단 메시지를 한국어로 번역해주는 Vim 플러그인입니다.

[rustlings-ko.nvim](https://github.com/eoncheole/rustlings-ko.nvim)의 classic Vim (8.2+) 포팅 버전입니다.

## 주요 기능

- **160개 이상의 에러 코드** (E0001~E0734) 한국어 번역
- **46개의 패턴 매칭** 기반 메시지 번역
- **10개의 경고**, **15개의 힌트** 메시지 번역
- **다중 백엔드 지원**: ALE, vim-lsp, coc.nvim, quickfix/loclist
- **자동 백엔드 감지**: 설치된 플러그인에 맞게 자동으로 연동
- **커서 위치 한국어 팝업** (coc.nvim): 에러 위에 커서를 놓으면 자동으로 한국어 진단 팝업 표시
- **저장 시 자동 빌드**: `cargo check`를 비동기로 실행하여 quickfix에 한국어 진단 표시
- **LLM 폴백**: 오프라인 매핑에 없는 메시지를 Anthropic Claude 또는 OpenAI GPT로 번역
- **LRU 캐시**: 번역 결과를 캐싱하여 성능 최적화
- **원문 표시**: 번역과 함께 원문 영어 메시지를 선택적으로 표시

## 스크린샷

```
  1 fn main() {
x 2     let x: i32 = "hello";
  1 }
        ┌─────────────────────────────────────────┐
        │ [에러 E0308]                              │
        │ i32, 예상되었지만 &'static str 발견되었습니다  │
        │                                           │
        │ [원문] expected i32, found &'static str    │
        └─────────────────────────────────────────┘
```

## 요구사항

- Vim 8.2 이상
- Rust 개발 환경 (`cargo`, `rustc`)

### 선택 사항

- [coc.nvim](https://github.com/neoclide/coc.nvim) + [coc-rust-analyzer](https://github.com/nicknisi/coc-rust-analyzer) (권장)
- [ALE](https://github.com/dense-analysis/ale)
- [vim-lsp](https://github.com/prabirshrestha/vim-lsp)
- `curl` (LLM 모드 사용 시)

## 설치

### vim-plug

```vim
Plug 'eoncheole/rustlings-ko.vim'
```

### Vundle

```vim
Plugin 'eoncheole/rustlings-ko.vim'
```

### Vim 패키지 (Vim 8+)

```bash
mkdir -p ~/.vim/pack/plugins/start
cd ~/.vim/pack/plugins/start
git clone https://github.com/eoncheole/rustlings-ko.vim
```

## 설정

### 기본 설정 (.vimrc)

```vim
" 플러그인 활성화/비활성화 (기본: 1)
let g:rustlings_ko_enabled = 1

" 번역 모드: 'mapping' (오프라인) 또는 'llm' (매핑 + LLM 폴백)
let g:rustlings_ko_mode = 'mapping'

" 번역 아래에 원문 영어 메시지 표시 (기본: 0)
let g:rustlings_ko_show_original = 1

" LRU 캐시 최대 크기 (기본: 500)
let g:rustlings_ko_cache_max_size = 500

" 백엔드 선택: 'auto', 'ale', 'vim-lsp', 'coc', 'quickfix'
let g:rustlings_ko_backend = 'auto'

" 저장 시 자동 cargo check 실행 (기본: 1, coc/quickfix 백엔드에서 활성)
let g:rustlings_ko_auto_check = 1
```

### coc.nvim 사용자 (권장 설정)

coc.nvim과 함께 사용할 경우, coc의 기본 진단 표시를 끄고 rustlings-ko의 한국어 팝업을 사용하는 것을 권장합니다.

**~/.vim/coc-settings.json** (`:CocConfig`으로 열기):

```json
{
    "diagnostic.virtualText": false,
    "diagnostic.virtualTextCurrentLineOnly": false,
    "diagnostic.messageTarget": "none"
}
```

| 설정 | 설명 |
|------|------|
| `diagnostic.virtualText: false` | coc의 영문 인라인 텍스트 비활성화 |
| `diagnostic.messageTarget: "none"` | coc의 영문 진단 팝업 비활성화 |

이 설정을 하면:
- **CursorHold**: 에러 위에 커서를 놓으면 한국어 팝업이 자동으로 표시됩니다
- **K 키**: 에러 줄에서 `K`를 누르면 한국어 진단 팝업, 정상 줄에서는 coc 문서 hover가 표시됩니다

### LLM 모드 설정

```vim
let g:rustlings_ko_mode = 'llm'
let g:rustlings_ko_llm_provider = 'anthropic'  " 또는 'openai'
let g:rustlings_ko_llm_api_key = $ANTHROPIC_API_KEY
```

## 명령어

| 명령어 | 설명 |
|--------|------|
| `:RustDiagKo enable` | 번역 활성화 |
| `:RustDiagKo disable` | 번역 비활성화 |
| `:RustDiagKo toggle` | 활성화/비활성화 전환 |
| `:RustDiagKo clear-cache` | 번역 캐시 초기화 |
| `:RustDiagKo status` | 현재 상태 표시 |

## 백엔드 자동 감지

플러그인은 다음 우선순위로 백엔드를 자동 감지합니다:

1. **vim-lsp** - `lsp_diagnostics_updated` 이벤트 사용
2. **coc.nvim** - `CocDiagnosticChange` 이벤트 + 한국어 팝업
3. **ALE** - `ALELintPost` 이벤트 사용
4. **quickfix** - `QuickFixCmdPost` 이벤트 사용 (항상 활성)

LSP 플러그인 없이도 `:make`, `:compiler cargo` 등으로 생성된 quickfix/location list의 메시지를 번역합니다.

## 프로젝트 구조

```
rustlings-ko.vim/
├── plugin/
│   └── rustlings_ko.vim          # 플러그인 진입점
├── autoload/
│   ├── rustlings_ko.vim          # 메인 코디네이터
│   └── rustlings_ko/
│       ├── cache.vim             # LRU 캐시
│       ├── translator.vim        # 번역 엔진
│       ├── mappings.vim          # 번역 데이터 + 룩업
│       ├── llm.vim               # LLM 폴백
│       ├── builder.vim           # 비동기 cargo check (저장 시 자동 빌드)
│       └── backend/
│           ├── ale.vim           # ALE 통합
│           ├── vim_lsp.vim       # vim-lsp 통합
│           └── coc.vim           # coc.nvim 통합 (한국어 팝업)
├── doc/
│   └── rustlings-ko.txt          # Vim 도움말
├── test/
│   └── test_translator.vim       # 테스트 스위트
└── README.md
```

## 테스트 실행

```bash
vim -u NONE -N --cmd 'set rtp+=.' --cmd 'source test/test_translator.vim' --cmd 'qa!'
```

## 라이선스

MIT License

## 크레딧

- 원본 프로젝트: [rustlings-ko.nvim](https://github.com/eoncheole/rustlings-ko.nvim)
- 한국어 번역 데이터는 원본 프로젝트에서 포팅되었습니다
