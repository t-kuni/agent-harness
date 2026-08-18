#!/bin/bash
# OpenAI Responses API (gpt-5.6-sol + web_search + reasoning effort medium) を呼び出し、
# リサーチプロンプトを実行して結果テキストを指定パスに保存する。
#
# 使い方:
#   deep_research_api.sh <PROMPT_PATH> <RESULT_PATH>
#
# 前提:
#   - 環境変数 OPENAI_API_KEY にAPIキーが設定されていること
#     （このスクリプト自体がシェルの環境変数を参照する。呼び出し元のAIエージェントが
#       環境変数を参照・存在確認する必要は無い）
#   - jq コマンドが利用可能なこと
#   - Web検索を多数回行い長時間かかりうるため、呼び出し元は Bash ツールの
#     run_in_background: true でこのスクリプトを実行すること
set -euo pipefail

PROMPT_PATH="${1:?PROMPT_PATH is required}"
RESULT_PATH="${2:?RESULT_PATH is required}"

if [ -z "${OPENAI_API_KEY:-}" ]; then
  echo "Error: OPENAI_API_KEY is not set" >&2
  exit 1
fi

if [ ! -f "$PROMPT_PATH" ]; then
  echo "Error: PROMPT_PATH not found: $PROMPT_PATH" >&2
  exit 1
fi

TMP_RESPONSE="$(mktemp)"
trap 'rm -f "$TMP_RESPONSE"' EXIT

REQUEST_BODY="$(jq -n \
  --arg model "gpt-5.6-sol" \
  --rawfile input "$PROMPT_PATH" \
  '{
    model: $model,
    input: $input,
    reasoning: {effort: "medium"},
    tools: [{type: "web_search_preview"}]
  }')"

curl -sS --max-time 1800 "https://api.openai.com/v1/responses" \
  -H "Authorization: Bearer ${OPENAI_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "$REQUEST_BODY" \
  -o "$TMP_RESPONSE"

if jq -e '.error' "$TMP_RESPONSE" > /dev/null 2>&1; then
  echo "Error: OpenAI API returned an error" >&2
  jq '.error' "$TMP_RESPONSE" >&2
  exit 1
fi

mkdir -p "$(dirname "$RESULT_PATH")"
jq -r '.output[] | select(.type == "message") | .content[] | select(.type == "output_text") | .text' "$TMP_RESPONSE" > "$RESULT_PATH"

if [ ! -s "$RESULT_PATH" ]; then
  echo "Error: could not extract output_text from response" >&2
  exit 1
fi

echo "Saved: $RESULT_PATH"
