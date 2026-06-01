#!/usr/bin/env bash
# agent-harness から新規プロジェクトを初期化するスクリプト
# curl でダウンロードして実行する想定：
#   PROJECT_NAME=myproject bash <(curl -fsSL https://raw.githubusercontent.com/t-kuni/agent-harness/main/meta-scripts/init-project.sh)
set -euo pipefail

HARNESS_URL="${HARNESS_URL:-https://github.com/t-kuni/agent-harness.git}"

if [ -z "${PROJECT_NAME:-}" ]; then
  echo "エラー: PROJECT_NAME 環境変数を指定してください。" >&2
  echo "使い方: PROJECT_NAME=myproject bash init-project.sh" >&2
  exit 1
fi

if [ -e "$PROJECT_NAME" ]; then
  echo "エラー: '$PROJECT_NAME' は既に存在します。" >&2
  exit 1
fi

echo "agent-harness をクローン中..."
git clone --quiet "$HARNESS_URL" "$PROJECT_NAME"
cd "$PROJECT_NAME"

# ハーネスバージョンを記録
git rev-parse HEAD > .harness-version

# git 履歴を切り離して独自リポジトリとして初期化
rm -rf .git
git init
git add .
git commit -m "Initial commit (from agent-harness)"

echo ""
echo "プロジェクト '$PROJECT_NAME' を作成しました。"
echo ""
echo "次のステップ："
echo "  cd $PROJECT_NAME"
echo "  bash meta-scripts/setup.sh"
echo ""
echo "agent-harness の更新を取り込む場合："
echo "  bash meta-scripts/update-harness.sh"
