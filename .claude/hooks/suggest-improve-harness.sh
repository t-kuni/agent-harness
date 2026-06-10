#!/usr/bin/env bash
set -euo pipefail

INPUT="$(cat)"
ACTIVE="$(jq -r '.stop_hook_active // false' <<< "$INPUT")"

# 無限ループ防止
if [[ "$ACTIVE" == "true" ]]; then
  exit 0
fi

# ジョブエージェント（claude -p）経由の場合は提案ファイルを書くよう指示
if [[ "${CLAUDE_JOB_AGENT:-}" == "1" ]]; then
  SESSION_ID="$(jq -r '.session_id // "unknown"' <<< "$INPUT")"
  TRANSCRIPT_PATH="$(jq -r '.transcript_path // "unknown"' <<< "$INPUT")"
  TIMESTAMP="$(date '+%Y%m%d-%H%M%S')"
  PROPOSAL_PATH="./improve-harness/${TIMESTAMP}.md"

  jq -n \
    --arg session_id "$SESSION_ID" \
    --arg transcript_path "$TRANSCRIPT_PATH" \
    --arg proposal_path "$PROPOSAL_PATH" \
    '{
      decision: "block",
      reason: ("このセッションの作業内容を振り返り、ハーネスに改善できる点がありそうか考えてください（追加の調査は不要）。ただし、作業が途中で続けてオーナーから指示があると思われる場合は改善提案はしないでください。改善できそうな点がある場合のみ、以下の書式で " + $proposal_path + " を作成してください。改善点がない場合は何もせず終了してください。\n\n```\n# ハーネス改善提案\n\n## セッション情報\n- Session ID: " + $session_id + "\n- Transcript: " + $transcript_path + "\n\n## 提案内容\n<!-- 改善提案をここに記載 -->\n```")
    }'
  exit 0
fi

jq -n '{ decision: "block", reason: "このセッションの作業内容を振り返り、ハーネスに改善できる点がありそうか考えてください（追加の調査は不要）。ただし、作業が途中で続けてオーナーから指示があると思われる場合は改善提案はしないでください。改善できそうな点があれば、その内容を簡潔にオーナーに伝えて改善するかどうか確認してください。その際、冒頭に【改善提案】ヘッダーを付け、各案に「改善提案#1」「改善提案#2」のように連番を振ること。オーナーがYESと答えた場合のみ /improve-harness を実行してください。改善点がない場合は、その旨を簡潔に述べて終了してください。\n\nなお、改善提案を提示した後にオーナーから返信が来た場合、「改善提案を修正して」「#1を直して」など改善提案の修正を明示的に求めている場合のみ改善提案の修正として扱うこと。それ以外の返信は改善提案の直前の話題への返信として解釈すること。" }'
