#!/usr/bin/env bash
# xAI Grok Imagine API（動画）を使い、プロンプト（＋任意で入力画像）から動画を生成し、
# 完了まで自動でポーリングして保存する。
#
# 前提:
#   - 環境変数 XAI_API_KEY にAPIキーが設定されていること
#     （このスクリプト自体がシェルの環境変数を参照する。呼び出し元のAIエージェントが
#       環境変数を参照・存在確認する必要は無い）
#   - curl, jq が利用可能なこと
#
# エンドポイント: POST /v1/videos/generations （非同期。request_idを返す）
#              GET  /v1/videos/{request_id}   （ポーリング。status: pending/done/expired/failed）
set -euo pipefail

MODEL="grok-imagine-video-1.5"
API_BASE="https://api.x.ai"

usage() {
  cat <<'EOS' >&2
使い方:
  generate_video.sh --prompt <プロンプト文字列> --out <保存先.mp4のパス> \
                     [--image <入力画像のパス>] \
                     [--duration <秒数(1-15)>] [--aspect-ratio <比率>] [--resolution <480p|720p|1080p>] \
                     [--poll-interval <秒数>] [--poll-timeout <秒数>]

オプション:
  --prompt TEXT       生成プロンプト（必須）
  --out FILE          生成動画の保存先パス（必須）
  --image FILE        入力画像（指定するとImage-to-video。省略時はText-to-video）
  --duration SEC       動画の長さ（1〜15秒。デフォルト8）
  --aspect-ratio RATIO 出力比率（1:1, 16:9, 9:16, 4:3, 3:4, 3:2, 2:3。デフォルト16:9。
                        Image-to-videoで省略した場合は入力画像の比率が使われる）
  --resolution RES     480p / 720p / 1080p（デフォルト480p）
  --poll-interval SEC  ポーリング間隔（デフォルト5秒）
  --poll-timeout SEC   最大待機時間（デフォルト900秒）
EOS
  exit 1
}

PROMPT=""
OUT=""
IMAGE=""
DURATION=""
ASPECT_RATIO=""
RESOLUTION=""
POLL_INTERVAL=5
POLL_TIMEOUT=900

while [ $# -gt 0 ]; do
  case "$1" in
    --prompt) PROMPT="$2"; shift 2 ;;
    --out) OUT="$2"; shift 2 ;;
    --image) IMAGE="$2"; shift 2 ;;
    --duration) DURATION="$2"; shift 2 ;;
    --aspect-ratio) ASPECT_RATIO="$2"; shift 2 ;;
    --resolution) RESOLUTION="$2"; shift 2 ;;
    --poll-interval) POLL_INTERVAL="$2"; shift 2 ;;
    --poll-timeout) POLL_TIMEOUT="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "ERROR: 不明な引数: $1" >&2; usage ;;
  esac
done

[ -z "$PROMPT" ] && { echo "ERROR: --prompt は必須です" >&2; usage; }
[ -z "$OUT" ] && { echo "ERROR: --out は必須です" >&2; usage; }
if [ -n "$IMAGE" ]; then
  [ -f "$IMAGE" ] || { echo "ERROR: 画像が見つかりません: $IMAGE" >&2; exit 1; }
fi
: "${XAI_API_KEY:?環境変数 XAI_API_KEY が未設定です}"

command -v curl >/dev/null || { echo "ERROR: curl が必要です" >&2; exit 1; }
command -v jq >/dev/null || { echo "ERROR: jq が必要です" >&2; exit 1; }

# --- 1. リクエストボディを組み立てる ---
BODY_ARGS=(--arg model "$MODEL" --arg prompt "$PROMPT")
BODY_JQ='{model: $model, prompt: $prompt}'

if [ -n "$DURATION" ]; then
  BODY_ARGS+=(--argjson duration "$DURATION")
  BODY_JQ="$BODY_JQ"' + {duration: $duration}'
fi
if [ -n "$ASPECT_RATIO" ]; then
  BODY_ARGS+=(--arg aspect_ratio "$ASPECT_RATIO")
  BODY_JQ="$BODY_JQ"' + {aspect_ratio: $aspect_ratio}'
fi
if [ -n "$RESOLUTION" ]; then
  BODY_ARGS+=(--arg resolution "$RESOLUTION")
  BODY_JQ="$BODY_JQ"' + {resolution: $resolution}'
fi
if [ -n "$IMAGE" ]; then
  MIME_TYPE="image/png"
  case "$IMAGE" in
    *.jpg|*.jpeg) MIME_TYPE="image/jpeg" ;;
    *.webp) MIME_TYPE="image/webp" ;;
  esac
  IMAGE_DATA_URI="data:${MIME_TYPE};base64,$(base64 -w0 "$IMAGE")"
  BODY_ARGS+=(--arg image_url "$IMAGE_DATA_URI")
  BODY_JQ="$BODY_JQ"' + {image: {url: $image_url}}'
fi

REQUEST_BODY="$(jq -n "${BODY_ARGS[@]}" "$BODY_JQ")"

echo "=== Grok Imagine 動画生成 ==="
echo "model: $MODEL / duration: ${DURATION:-default} / aspect_ratio: ${ASPECT_RATIO:-default} / resolution: ${RESOLUTION:-default}"
[ -n "$IMAGE" ] && echo "image: $IMAGE"
echo "out: $OUT"

# --- 2. 生成タスクを投入 ---
CREATE_RESPONSE=$(curl -sS -X POST "${API_BASE}/v1/videos/generations" \
  -H "Authorization: Bearer ${XAI_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "$REQUEST_BODY")

REQUEST_ID=$(echo "$CREATE_RESPONSE" | jq -r '.request_id // empty')
if [ -z "$REQUEST_ID" ]; then
  echo "ERROR: request_id を取得できませんでした。レスポンス:" >&2
  echo "$CREATE_RESPONSE" >&2
  exit 1
fi
echo "request_id: $REQUEST_ID"

# --- 3. ステータスをポーリング ---
ELAPSED=0
STATUS=""
VIDEO_URL=""
while [ "$ELAPSED" -lt "$POLL_TIMEOUT" ]; do
  sleep "$POLL_INTERVAL"
  ELAPSED=$((ELAPSED + POLL_INTERVAL))

  POLL_RESPONSE=$(curl -sS -X GET "${API_BASE}/v1/videos/${REQUEST_ID}" \
    -H "Authorization: Bearer ${XAI_API_KEY}")

  STATUS=$(echo "$POLL_RESPONSE" | jq -r '.status // empty')
  echo "[$(date '+%H:%M:%S')] status: ${STATUS:-unknown} (経過${ELAPSED}s)"

  case "$STATUS" in
    done)
      VIDEO_URL=$(echo "$POLL_RESPONSE" | jq -r '.video.url // empty')
      break
      ;;
    failed|expired)
      echo "ERROR: 生成が失敗しました（status: $STATUS）。レスポンス:" >&2
      echo "$POLL_RESPONSE" >&2
      exit 1
      ;;
  esac
done

if [ -z "$VIDEO_URL" ]; then
  echo "ERROR: タイムアウト（${POLL_TIMEOUT}秒）または動画URLを取得できませんでした" >&2
  exit 1
fi

# --- 4. ダウンロード（一時URLのため即座に取得する） ---
mkdir -p "$(dirname "$OUT")"
curl -sS -L -o "$OUT" "$VIDEO_URL"
echo "完了: $OUT ($(du -h "$OUT" | cut -f1))"
