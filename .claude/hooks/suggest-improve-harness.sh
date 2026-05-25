#!/usr/bin/env bash
set -euo pipefail

INPUT="$(cat)"
ACTIVE="$(jq -r '.stop_hook_active // false' <<< "$INPUT")"

# 無限ループ防止
if [[ "$ACTIVE" == "true" ]]; then
  exit 0
fi

# ジョブエージェント（claude -p）経由の場合はスキップ
if [[ "${CLAUDE_JOB_AGENT:-}" == "1" ]]; then
  exit 0
fi

jq -n '{ decision: "block", reason: "このセッションの作業内容を振り返り、ハーネスに改善できる点がありそうか考えてください（追加の調査は不要）。改善できそうな点があれば、その内容を簡潔にオーナーに伝えて改善するかどうか確認してください。オーナーがYESと答えた場合のみ /improve-harness を実行してください。改善点がない場合は、その旨を簡潔に述べて終了してください。" }'
