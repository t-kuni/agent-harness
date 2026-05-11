#!/usr/bin/env bash
set -euo pipefail

INPUT="$(cat)"
ACTIVE="$(jq -r '.stop_hook_active // false' <<< "$INPUT")"
SESSION_ID="$(jq -r '.session_id // "unknown"' <<< "$INPUT")"
SENTINEL="/tmp/auto-improve-harness-${SESSION_ID}.done"

# 無限ループ防止：1セッション1回だけ発火
if [[ "$ACTIVE" == "true" || -f "$SENTINEL" ]]; then
  exit 0
fi

touch "$SENTINEL"

jq -n '{ decision: "block", reason: "Before stopping, review this session for tool failures, permission errors, repeated attempts, or avoidable detours. If a concrete improvement to the harness exists, invoke /improve-harness. If no actionable improvement exists, state that briefly and finish." }'
