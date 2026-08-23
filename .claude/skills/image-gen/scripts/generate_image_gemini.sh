#!/bin/bash
# Google Gemini API（Gemini 3.1 Flash Image、通称 nano banana2）を呼び出して画像を生成し、指定パスに保存する。
#
# 使い方:
#   generate_image_gemini.sh <PROMPT> <OUTPUT_PATH> [REF_IMAGE_1,REF_IMAGE_2,...] [ASPECT_RATIO] [IMAGE_SIZE]
#
# 前提:
#   - 環境変数 GEMINI_API_KEY にAPIキーが設定されていること
#     （このスクリプト自体がシェルの環境変数を参照する。呼び出し元のAIエージェントが
#       環境変数を参照・存在確認する必要は無い）
#   - jq コマンドが利用可能なこと
#
# ASPECT_RATIO:
#   - "1:1", "2:3", "3:2", "3:4", "4:3", "4:5", "5:4", "9:16", "16:9", "21:9", "1:8", "8:1", "1:4", "4:1"
#   - 省略時は "16:9"
#   - OpenAI方式（gpt-image-2）のような "WIDTHxHEIGHT" の任意解像度指定ではなく、比率＋サイズクラスの組み合わせ指定である点に注意
#
# IMAGE_SIZE:
#   - "512", "1K", "2K", "4K"（"512" は gemini-3.1-flash-image のみ対応）
#   - 省略時は "1K"
#
# エンドポイント:
#   - 参照画像の有無によらず同一エンドポイント POST /v1beta/interactions を使う
#     （OpenAI方式のように generations/edits でエンドポイントが分かれていない）
set -euo pipefail

PROMPT="${1:?PROMPT is required}"
OUTPUT_PATH="${2:?OUTPUT_PATH is required}"
REF_IMAGES="${3:-}"
ASPECT_RATIO="${4:-16:9}"
IMAGE_SIZE="${5:-1K}"

if [ -z "${GEMINI_API_KEY:-}" ]; then
  echo "Error: GEMINI_API_KEY is not set" >&2
  exit 1
fi

# input配列を構築: テキストを先頭に、参照画像を後続に並べる
INPUT_JSON="$(jq -n --arg text "$PROMPT" '[{type:"text", text:$text}]')"

if [ -n "$REF_IMAGES" ]; then
  IFS=',' read -ra IMG_ARRAY <<< "$REF_IMAGES"
  for img in "${IMG_ARRAY[@]}"; do
    case "$img" in
      *.png) MIME="image/png" ;;
      *.jpg|*.jpeg) MIME="image/jpeg" ;;
      *.webp) MIME="image/webp" ;;
      *) MIME="image/png" ;;
    esac
    B64_DATA="$(base64 -w 0 "$img")"
    INPUT_JSON="$(jq -n --argjson acc "$INPUT_JSON" --arg mime "$MIME" --arg data "$B64_DATA" \
      '$acc + [{type:"image", mime_type:$mime, data:$data}]')"
  done
fi

REQUEST_BODY="$(jq -n \
  --arg model "gemini-3.1-flash-image" \
  --argjson input "$INPUT_JSON" \
  --arg aspect_ratio "$ASPECT_RATIO" \
  --arg image_size "$IMAGE_SIZE" \
  '{model: $model, input: $input, response_format: {type: "image", mime_type: "image/jpeg", aspect_ratio: $aspect_ratio, image_size: $image_size}}')"

TMP_RESPONSE="$(mktemp)"
trap 'rm -f "$TMP_RESPONSE"' EXIT

curl -sS "https://generativelanguage.googleapis.com/v1beta/interactions" \
  -H "x-goog-api-key: ${GEMINI_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "$REQUEST_BODY" \
  -o "$TMP_RESPONSE"

if jq -e '.error' "$TMP_RESPONSE" > /dev/null 2>&1; then
  echo "Error: Gemini API returned an error" >&2
  jq '.error' "$TMP_RESPONSE" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUTPUT_PATH")"
jq -r '.steps[] | select(.type=="model_output") | .content[] | select(.type=="image") | .data' "$TMP_RESPONSE" | head -1 | base64 -d > "$OUTPUT_PATH"

if [ ! -s "$OUTPUT_PATH" ]; then
  echo "Error: failed to extract image data from response" >&2
  cat "$TMP_RESPONSE" >&2
  exit 1
fi

echo "Saved: $OUTPUT_PATH"
