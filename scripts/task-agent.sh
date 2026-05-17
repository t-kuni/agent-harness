#!/bin/bash
# TASK.mdの先頭タスクを順次処理するループスクリプト
# 使い方: bash scripts/task-agent.sh [待機秒数]
# 環境変数:
#   CLAUDE_MODEL: 使用するモデル（デフォルト: claude-sonnet-4-6）

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TASK_FILE="$PROJECT_DIR/TASK.md"
WAIT_SECONDS="${1:-60}"
CLAUDE_MODEL="${CLAUDE_MODEL:-claude-sonnet-4-6}"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

log "タスク処理エージェントを開始します (TASK.md: $TASK_FILE, モデル: ${CLAUDE_MODEL}, 待機時間: ${WAIT_SECONDS}秒)"

PROMPT='あなたはタスク処理エージェントです。以下の手順を実行してください。

手順:
1. TASK.mdを読み込む
2. TASK.mdの一番上にある未完了タスク（`* [ ]` で始まる行）を1つ選ぶ
3. そのタスクを処理する
4. タスクが完了したら、TASK.mdからそのタスクと補足行（直下にインデントされた行）を削除する
5. 全タスクが完了した場合はTASK.mdを空（0byte）にする

重要なルール:
- 処理するのは1タスクだけ。複数タスクを一度に処理しない
- タスクを削除する際は、`* [ ] タスク内容` 行と、その直下の補足行（`    *` で始まる行）も合わせて削除する
- タスク処理に必要であればハーネスや外部ツールを活用してよい
- タスク処理の過程で新たなタスクが発生した場合は、TASK.mdの適切な位置に挿入する（依存関係に注意して順序を決める）
- タスクに参照ハーネスが記載されている場合は、そのハーネスを必ず参照してからタスクを遂行すること'

while true; do
  # TASK.mdが空(0byte)かどうか決定論的にチェック
  if [ ! -s "$TASK_FILE" ]; then
    log "TASK.mdが空です。${WAIT_SECONDS}秒待機します..."
    sleep "$WAIT_SECONDS"
    log "待機終了。ループを終了します。"
    exit 0
  fi

  log "タスクを検出しました。claude -p で処理を開始します..."

  cd "$PROJECT_DIR"
  claude -p "$PROMPT" \
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
    log "タスク処理完了。"
  else
    log "エラー: claude -p が終了コード ${EXIT_CODE} で失敗しました。"
    notify-send "タスクエージェント エラー" "claude -p が失敗しました (終了コード: ${EXIT_CODE})" 2>/dev/null || true
    exit "$EXIT_CODE"
  fi
done
