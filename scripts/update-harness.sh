#!/usr/bin/env bash
# このリポジトリ（agent-harness）の更新を取り込むスクリプト
# 派生先リポジトリのルートで実行する
set -euo pipefail

HARNESS_URL="${HARNESS_URL:-https://github.com/t-kuni/agent-harness.git}"
VERSION_FILE=".harness-version"

# 作業ツリーがクリーンであることを確認
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "エラー: 未コミットの変更があります。先にコミットしてください。" >&2
  exit 1
fi

# ハーネスバージョンを読み込む
if [ ! -f "$VERSION_FILE" ]; then
  echo "エラー: $VERSION_FILE が見つかりません。" >&2
  exit 1
fi
BASE="$(cat "$VERSION_FILE")"

# /tmp にクローンして差分を生成
TMPDIR="$(mktemp -d /tmp/agent-harness-update.XXXXXX)"
trap 'rm -rf "$TMPDIR"' EXIT

echo "agent-harness を取得中..."
git clone --quiet "$HARNESS_URL" "$TMPDIR"

LATEST="$(git -C "$TMPDIR" rev-parse HEAD)"

if [ "$BASE" = "$LATEST" ]; then
  echo "既に最新のハーネスバージョンです。"
  exit 0
fi

echo "更新範囲: ${BASE:0:12}..${LATEST:0:12}"

# /tmp のクローンから差分を生成して適用
PATCH_FILE="$TMPDIR/harness-update.patch"
git -C "$TMPDIR" diff --binary "$BASE" "$LATEST" > "$PATCH_FILE"

if ! git apply --check --3way "$PATCH_FILE" 2>/dev/null; then
  echo "警告: コンフリクトが発生します。手動での解決が必要です。"
fi

git apply --3way --index "$PATCH_FILE" || {
  echo ""
  echo "コンフリクトが発生しました。以下の手順で解決してください："
  echo "  1. git status でコンフリクトファイルを確認"
  echo "  2. ファイルを編集して解決"
  echo "  3. git add <解決したファイル>"
  echo "  4. echo '$LATEST' > $VERSION_FILE && git add $VERSION_FILE"
  echo "  5. git commit -m 'Apply harness updates ${BASE:0:12}..${LATEST:0:12}'"
  exit 1
}

# ハーネスバージョンを更新
printf '%s\n' "$LATEST" > "$VERSION_FILE"
git add "$VERSION_FILE"

git commit -m "Apply harness updates ${BASE:0:12}..${LATEST:0:12}"

echo ""
echo "完了しました。"
