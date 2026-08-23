#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENV_DIR="$ROOT_DIR/.venv"

echo "=== agent-harness セットアップ ==="

# Python の確認
if ! command -v python3 &>/dev/null; then
  echo "ERROR: python3 が見つかりません。インストールしてください。" >&2
  exit 1
fi

# venv の作成
if [ ! -d "$VENV_DIR" ]; then
  echo "venv を作成します: $VENV_DIR"
  python3 -m venv "$VENV_DIR"
else
  echo "既存の venv を使用します: $VENV_DIR"
fi

# 依存パッケージのインストール（random-word スキル用、image-gen スキル用）
echo "依存パッケージをインストールします..."
"$VENV_DIR/bin/pip" install --quiet --upgrade pip
"$VENV_DIR/bin/pip" install --quiet -r "$ROOT_DIR/.claude/skills/random-word/requirements.txt"
"$VENV_DIR/bin/pip" install --quiet -r "$ROOT_DIR/.claude/skills/image-gen/scripts/requirements.txt"

echo ""
echo "セットアップ完了。"
echo "トレンドワード取得コマンド:"
echo "  .venv/bin/python .claude/skills/random-word/trends24_pick.py [件数]"
