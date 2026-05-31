#!/usr/bin/env bash
# このリポジトリ（agent-harness）の更新を取り込むスクリプト
# 派生先リポジトリのルートで実行する
#
# 【ローカルでのテスト方法】
# HARNESS_URL にローカルパスを指定することで GitHub クローンを省略できる。
# コンフリクトのシナリオをテストする手順:
#
#   # 1. テスト用派生リポジトリを作成
#   mkdir /tmp/test-derived && cd /tmp/test-derived && git init && git commit --allow-empty -m "init"
#
#   # 2. BASE をいくつか前のコミットに設定し、そのコミット時点のファイルをコピー
#   BASE=$(git -C ~/path/to/agent-harness log --oneline | sed -n '3p' | awk '{print $1}')
#   FULL_BASE=$(git -C ~/path/to/agent-harness rev-parse "$BASE")
#   git -C ~/path/to/agent-harness show "$BASE:<ファイルパス>" > /tmp/test-derived/<ファイルパス>
#   echo "$FULL_BASE" > .harness-version
#   git add . && git commit -m "initial harness"
#
#   # 3. ローカルで変更を加えてコンフリクト要因を作る
#   echo "# local change" >> <ファイルパス>
#   git add . && git commit -m "local modification"
#
#   # 4. スクリプト実行
#   HARNESS_URL=~/path/to/agent-harness bash ~/path/to/agent-harness/meta-scripts/update-harness.sh
#
# コンフリクト時の挙動:
#   - 適用できたファイル → ワークツリーに反映（git status に modified で表示）
#   - 適用できなかったハンク → <ファイル名>.rej に出力
#   - 全体はロールバックされない（--reject による部分適用）
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

if ! git apply --check "$PATCH_FILE" 2>/dev/null; then
  echo "警告: コンフリクトが発生します。手動での解決が必要です。"
fi

git apply --reject "$PATCH_FILE" || {
  echo ""
  echo "コンフリクトが発生しました。以下の手順で解決してください："
  echo "  1. git status でコンフリクトファイルを確認（<<<< マーカーあり）"
  echo "  2. *.rej ファイルを確認して手動でマージ（適用できなかったハンク）"
  echo "  3. *.rej ファイルを削除"
  echo "  4. git add <解決したファイル>"
  echo "  5. echo '$LATEST' > $VERSION_FILE && git add $VERSION_FILE"
  echo "  6. git commit -m 'Apply harness updates ${BASE:0:12}..${LATEST:0:12}'"
  echo ""
  echo "コンフリクトのあるファイル:"
  find . -name "*.rej" | sort
  exit 1
}

# ハーネスバージョンを更新
printf '%s\n' "$LATEST" > "$VERSION_FILE"

# --index を使わないためワークツリーの変更を手動でステージ
git add -A

git commit -m "Apply harness updates ${BASE:0:12}..${LATEST:0:12}"

echo ""
echo "完了しました。"
