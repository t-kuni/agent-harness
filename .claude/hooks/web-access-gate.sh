#!/bin/bash

INPUT=$(cat)

AGENT_ID=$(echo "$INPUT" | jq -r '.agent_id // ""')
AGENT_TYPE=$(echo "$INPUT" | jq -r '.agent_type // ""')

if [[ -n "$AGENT_ID" && "$AGENT_TYPE" == "web-researcher" ]]; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "permissionDecisionReason": "Web access allowed for web-researcher subagent"
  }
}
EOF
else
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Web access is restricted to the web-researcher subagent"
  }
}
EOF
fi
