#!/bin/bash
# JOB.mdの先頭ジョブを順次処理するループスクリプト
# 使い方: bash meta-scripts/job-agent.sh [待機秒数]
# 環境変数:
#   CLAUDE_MODEL: 使用するモデル（デフォルト: claude-sonnet-4-6）

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
JOB_FILE="$PROJECT_DIR/JOB.md"
WAIT_SECONDS="${1:-60}"
CLAUDE_MODEL="${CLAUDE_MODEL:-claude-sonnet-4-6}"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

log "ジョブ処理エージェントを開始します (JOB.md: $JOB_FILE, モデル: ${CLAUDE_MODEL}, 待機時間: ${WAIT_SECONDS}秒)"

PROMPT='あなたはジョブ処理エージェントです。以下の手順を実行してください。

手順:
1. JOB.mdを読み込む
2. JOB.mdの一番上にある未完了ジョブ（`* [ ]` で始まる行）を1つ選ぶ
3. そのジョブを処理する
4. ジョブが完了したら、JOB.mdからそのジョブと補足行（直下にインデントされた行）を削除する
5. 全ジョブが完了した場合はJOB.mdを空（0byte）にする

重要なルール:
- 処理するのは1ジョブだけ。複数ジョブを一度に処理しない
- ジョブを削除する際は、`* [ ] ジョブ内容` 行と、その直下の補足行（`    *` で始まる行）も合わせて削除する
- ジョブ処理に必要であればハーネスや外部ツールを活用してよい
- ジョブ処理の過程で新たなジョブが発生した場合は、JOB.mdの適切な位置に挿入する（依存関係に注意して順序を決める）
- ジョブに参照ハーネスが記載されている場合は、そのハーネスを必ず参照してからジョブを遂行すること'

while true; do
  # JOB.mdが空(0byte)かどうか決定論的にチェック
  if [ ! -s "$JOB_FILE" ]; then
    log "JOB.mdが空です。${WAIT_SECONDS}秒待機します..."
    sleep "$WAIT_SECONDS"
    continue
  fi

  log "ジョブを検出しました。claude -p で処理を開始します..."

  cd "$PROJECT_DIR"
  CLAUDE_JOB_AGENT=1 claude -p "$PROMPT" \
    --model "$CLAUDE_MODEL" \
    --dangerously-skip-permissions \
    --verbose \
    --output-format stream-json \
    | while IFS= read -r line; do
        echo "$line" | jq -r '
          if .type == "assistant" then
            (.message.content // [])[] |
            if .type == "tool_use" then
              "[TOOL] \(.name) \(.input | tostring | .[0:200])"
            elif .type == "text" and (.text | length > 0) then
              .text
            else empty end
          elif .type == "result" and .subtype == "error" then
            "[ERROR] \(.result // "")"
          else empty end
        ' 2>/dev/null || true
      done
  EXIT_CODE="${PIPESTATUS[0]}"

  if [ "$EXIT_CODE" -eq 0 ]; then
    log "ジョブ処理完了。"
  else
    log "エラー: claude -p が終了コード ${EXIT_CODE} で失敗しました。"
    notify-send "ジョブエージェント エラー" "claude -p が失敗しました (終了コード: ${EXIT_CODE})" 2>/dev/null || true
    exit "$EXIT_CODE"
  fi
done
