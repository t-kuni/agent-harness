#!/bin/bash
# xAI Grok Imagine API（画像）を呼び出して画像を生成し、指定パスに保存する。
#
# 使い方:
#   generate_image.sh <PROMPT> <OUTPUT_PATH> [REF_IMAGE_1,REF_IMAGE_2,...] [ASPECT_RATIO] [RESOLUTION]
#
# 前提:
#   - 環境変数 XAI_API_KEY にAPIキーが設定されていること
#     （このスクリプト自体がシェルの環境変数を参照する。呼び出し元のAIエージェントが
#       環境変数を参照・存在確認する必要は無い）
#   - jq コマンドが利用可能なこと
#
# 参照画像なし: POST /v1/images/generations
# 参照画像あり: POST /v1/images/edits（xAIはmultipartではなくJSON。画像は最大3枚まで）
#
# ASPECT_RATIO: 1:1, 3:4, 4:3, 9:16, 16:9, 2:3, 3:2, 9:19.5, 19.5:9, 9:20, 20:9,
#               1:2, 2:1, 21:9, 5:2, auto（省略時 auto）
# RESOLUTION: 1k, 2k（省略時 1k）
set -euo pipefail

MODEL="grok-imagine-image-2.0"

PROMPT="${1:?PROMPT is required}"
OUTPUT_PATH="${2:?OUTPUT_PATH is required}"
REF_IMAGES="${3:-}"
ASPECT_RATIO="${4:-auto}"
RESOLUTION="${5:-1k}"

if [ -z "${XAI_API_KEY:-}" ]; then
  echo "Error: XAI_API_KEY is not set" >&2
  exit 1
fi

command -v jq >/dev/null || { echo "Error: jq is required" >&2; exit 1; }

TMP_RESPONSE="$(mktemp)"
trap 'rm -f "$TMP_RESPONSE"' EXIT

# 参照画像をdata URI化するヘルパー
to_data_uri() {
  local img="$1"
  local mime="image/png"
  case "$img" in
    *.jpg|*.jpeg) mime="image/jpeg" ;;
    *.webp) mime="image/webp" ;;
  esac
  printf 'data:%s;base64,%s' "$mime" "$(base64 -w0 "$img")"
}

if [ -n "$REF_IMAGES" ]; then
  # 参照画像あり: /v1/images/edits (JSON, 最大3枚)
  IFS=',' read -ra IMG_ARRAY <<< "$REF_IMAGES"
  if [ "${#IMG_ARRAY[@]}" -gt 3 ]; then
    echo "Error: 参照画像は最大3枚まで（渡された枚数: ${#IMG_ARRAY[@]}）" >&2
    exit 1
  fi

  IMAGES_JSON="[]"
  for img in "${IMG_ARRAY[@]}"; do
    [ -f "$img" ] || { echo "Error: 参照画像が見つかりません: $img" >&2; exit 1; }
    DATA_URI="$(to_data_uri "$img")"
    IMAGES_JSON="$(echo "$IMAGES_JSON" | jq --arg url "$DATA_URI" '. + [{url: $url}]')"
  done

  REQUEST_BODY="$(jq -n \
    --arg model "$MODEL" \
    --arg prompt "$PROMPT" \
    --arg resolution "$RESOLUTION" \
    --argjson images "$IMAGES_JSON" \
    '{model: $model, prompt: $prompt, images: $images, resolution: $resolution, response_format: "b64_json"}')"

  curl -sS "https://api.x.ai/v1/images/edits" \
    -H "Authorization: Bearer ${XAI_API_KEY}" \
    -H "Content-Type: application/json" \
    -d "$REQUEST_BODY" \
    -o "$TMP_RESPONSE"
else
  # 参照画像なし: /v1/images/generations
  REQUEST_BODY="$(jq -n \
    --arg model "$MODEL" \
    --arg prompt "$PROMPT" \
    --arg aspect_ratio "$ASPECT_RATIO" \
    --arg resolution "$RESOLUTION" \
    '{model: $model, prompt: $prompt, aspect_ratio: $aspect_ratio, resolution: $resolution, response_format: "b64_json"}')"

  curl -sS "https://api.x.ai/v1/images/generations" \
    -H "Authorization: Bearer ${XAI_API_KEY}" \
    -H "Content-Type: application/json" \
    -d "$REQUEST_BODY" \
    -o "$TMP_RESPONSE"
fi

if jq -e '.error, .code' "$TMP_RESPONSE" > /dev/null 2>&1; then
  echo "Error: xAI API returned an error" >&2
  cat "$TMP_RESPONSE" >&2
  exit 1
fi

B64="$(jq -r '.data[0].b64_json // empty' "$TMP_RESPONSE")"
if [ -z "$B64" ]; then
  echo "Error: レスポンスに画像データが含まれていません" >&2
  cat "$TMP_RESPONSE" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUTPUT_PATH")"
echo "$B64" | base64 -d > "$OUTPUT_PATH"

echo "Saved: $OUTPUT_PATH"
