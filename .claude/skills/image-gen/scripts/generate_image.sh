#!/bin/bash
# OpenAI gpt-image-2 API を呼び出して画像を生成し、指定パスに保存する。
#
# 使い方:
#   generate_image.sh <PROMPT> <OUTPUT_PATH> [REF_IMAGE_1,REF_IMAGE_2,...] [SIZE]
#
# 前提:
#   - 環境変数 OPENAI_API_KEY にAPIキーが設定されていること
#     （このスクリプト自体がシェルの環境変数を参照する。呼び出し元のAIエージェントが
#       環境変数を参照・存在確認する必要は無い）
#   - jq コマンドが利用可能なこと
#
# SIZE:
#   - `/v1/images/generations`・`/v1/images/edits` 両方に共通の `size` パラメータとして渡す
#     （参照画像の有無でエンドポイントが変わっても解像度を統一するため）
#   - 省略時は "auto"（モデルが自動選択、固定解像度ではない）
#   - gpt-image-2 は "WIDTHxHEIGHT" 形式で任意解像度を指定できる
#     （幅・高さが16の倍数、長辺:短辺が3:1以内、総ピクセル数655,360〜8,294,400の制約あり）
set -euo pipefail

PROMPT="${1:?PROMPT is required}"
OUTPUT_PATH="${2:?OUTPUT_PATH is required}"
REF_IMAGES="${3:-}"
SIZE="${4:-auto}"

if [ -z "${OPENAI_API_KEY:-}" ]; then
  echo "Error: OPENAI_API_KEY is not set" >&2
  exit 1
fi

TMP_RESPONSE="$(mktemp)"
trap 'rm -f "$TMP_RESPONSE"' EXIT

if [ -n "$REF_IMAGES" ]; then
  # 参照画像あり: /v1/images/edits (multipart/form-data)
  IFS=',' read -ra IMG_ARRAY <<< "$REF_IMAGES"
  CURL_FORM_ARGS=()
  for img in "${IMG_ARRAY[@]}"; do
    CURL_FORM_ARGS+=(-F "image[]=@${img}")
  done
  curl -sS "https://api.openai.com/v1/images/edits" \
    -H "Authorization: Bearer ${OPENAI_API_KEY}" \
    -F model="gpt-image-2" \
    "${CURL_FORM_ARGS[@]}" \
    -F prompt="${PROMPT}" \
    -F size="${SIZE}" \
    -o "$TMP_RESPONSE"
else
  # 参照画像なし: /v1/images/generations (application/json)
  REQUEST_BODY="$(jq -n --arg model "gpt-image-2" --arg prompt "$PROMPT" --arg size "$SIZE" \
    '{model: $model, prompt: $prompt, size: $size, quality: "high", n: 1}')"
  curl -sS "https://api.openai.com/v1/images/generations" \
    -H "Authorization: Bearer ${OPENAI_API_KEY}" \
    -H "Content-Type: application/json" \
    -d "$REQUEST_BODY" \
    -o "$TMP_RESPONSE"
fi

if jq -e '.error' "$TMP_RESPONSE" > /dev/null 2>&1; then
  echo "Error: OpenAI API returned an error" >&2
  jq '.error' "$TMP_RESPONSE" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUTPUT_PATH")"
jq -r '.data[0].b64_json' "$TMP_RESPONSE" | base64 -d > "$OUTPUT_PATH"

echo "Saved: $OUTPUT_PATH"
