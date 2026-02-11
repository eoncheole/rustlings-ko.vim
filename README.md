# rustlings-ko.vim

Rust 컴파일러 진단 메시지를 한국어로 번역해주는 Vim 플러그인입니다.

[rustlings-ko.nvim](https://github.com/eoncheole/rustlings-ko.nvim)의 classic Vim (8.2+) 포팅 버전입니다.

## 주요 기능

- **160개 이상의 에러 코드** (E0001~E0734) 한국어 번역
- **46개의 패턴 매칭** 기반 메시지 번역
- **10개의 경고**, **15개의 힌트** 메시지 번역
- **다중 백엔드 지원**: ALE, vim-lsp, coc.nvim, quickfix/loclist
- **자동 백엔드 감지**: 설치된 플러그인에 맞게 자동으로 연동
- **LLM 폴백**: 오프라인 매핑에 없는 메시지를 Anthropic Claude 또는 OpenAI GPT로 번역
- **LRU 캐시**: 번역 결과를 캐싱하여 성능 최적화
- **원문 표시**: 번역과 함께 원문 영어 메시지를 선택적으로 표시

## 요구사항

- Vim 8.2 이상
- Rust 개발 환경

### 선택 사항

- [ALE](https://github.com/dense-analysis/ale)
- [vim-lsp](https://github.com/prabirshrestha/vim-lsp)
- [coc.nvim](https://github.com/neoclide/coc.nvim)
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

```vim
" 플러그인 활성화/비활성화 (기본: 1)
let g:rustlings_ko_enabled = 1

" 번역 모드: 'mapping' (오프라인) 또는 'llm' (매핑 + LLM 폴백)
let g:rustlings_ko_mode = 'mapping'

" 번역 아래에 원문 영어 메시지 표시 (기본: 0)
let g:rustlings_ko_show_original = 0

" LRU 캐시 최대 크기 (기본: 500)
let g:rustlings_ko_cache_max_size = 500

" 백엔드 선택: 'auto', 'ale', 'vim-lsp', 'coc', 'quickfix'
let g:rustlings_ko_backend = 'auto'

" 번역된 메시지 형식 (printf 스타일)
let g:rustlings_ko_diagnostics_format = '%s'

" 원문 메시지 형식
let g:rustlings_ko_original_format = "\n[원문] %s"
```

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
2. **coc.nvim** - `CocDiagnosticChange` 이벤트 사용
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
│       └── backend/
│           ├── ale.vim           # ALE 통합
│           ├── vim_lsp.vim       # vim-lsp 통합
│           └── coc.vim           # coc.nvim 통합
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
