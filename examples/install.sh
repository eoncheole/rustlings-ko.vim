#!/bin/bash
# rustlings-ko.vim 원클릭 설치 스크립트
# 사용법: curl -fsSL <URL> | bash  또는  bash install.sh

set -e

echo "====================================="
echo "  Rust 한국어 진단 Vim 환경 설치"
echo "====================================="
echo ""

# 1. vim-plug 설치
if [ ! -f ~/.vim/autoload/plug.vim ]; then
    echo "[1/5] vim-plug 설치 중..."
    curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    echo "  -> vim-plug 설치 완료"
else
    echo "[1/5] vim-plug 이미 설치되어 있음"
fi

# 2. vimrc 복사
echo "[2/5] vimrc 설정 중..."
if [ -f ~/.vimrc ]; then
    cp ~/.vimrc ~/.vimrc.backup.$(date +%Y%m%d%H%M%S)
    echo "  -> 기존 .vimrc를 백업했습니다"
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$SCRIPT_DIR/vimrc" ]; then
    cp "$SCRIPT_DIR/vimrc" ~/.vimrc
else
    curl -fsSL https://raw.githubusercontent.com/eoncheole/rustlings-ko.vim/master/examples/vimrc -o ~/.vimrc
fi
echo "  -> .vimrc 설정 완료"

# 3. coc-settings.json 복사
echo "[3/5] coc-settings.json 설정 중..."
mkdir -p ~/.vim
if [ -f ~/.vim/coc-settings.json ]; then
    cp ~/.vim/coc-settings.json ~/.vim/coc-settings.json.backup.$(date +%Y%m%d%H%M%S)
    echo "  -> 기존 coc-settings.json을 백업했습니다"
fi

if [ -f "$SCRIPT_DIR/coc-settings.json" ]; then
    cp "$SCRIPT_DIR/coc-settings.json" ~/.vim/coc-settings.json
else
    curl -fsSL https://raw.githubusercontent.com/eoncheole/rustlings-ko.vim/master/examples/coc-settings.json -o ~/.vim/coc-settings.json
fi
echo "  -> coc-settings.json 설정 완료"

# 4. 플러그인 설치
echo "[4/5] Vim 플러그인 설치 중... (시간이 좀 걸릴 수 있습니다)"
vim +PlugInstall +qall 2>/dev/null
echo "  -> 플러그인 설치 완료"

# 5. coc-rust-analyzer 설치
echo "[5/5] coc-rust-analyzer 설치 중..."
vim +"CocInstall -sync coc-rust-analyzer" +qall 2>/dev/null
echo "  -> coc-rust-analyzer 설치 완료"

echo ""
echo "====================================="
echo "  설치 완료!"
echo "====================================="
echo ""
echo "  vim으로 .rs 파일을 열면 한국어 에러가 표시됩니다."
echo ""
echo "  필수 요구사항:"
echo "    - Vim 8.2+      : vim --version 으로 확인"
echo "    - Node.js 16+   : node --version 으로 확인 (coc.nvim용)"
echo "    - Rust           : rustc --version 으로 확인"
echo "    - rust-analyzer  : rustup component add rust-analyzer"
echo ""
echo "  플러그인 업데이트: Vim에서 :PlugUpdate 실행"
echo ""
