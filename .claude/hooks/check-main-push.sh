#!/bin/bash
set -euo pipefail

INPUT=$(cat)
COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
  exit 0
fi

# main / master への直接プッシュをブロック
if printf '%s\n' "$COMMAND" | grep -Eiq \
  'git[[:space:]]+push[[:space:]]+(origin[[:space:]]+)?(main|master)([[:space:]]|$)'; then
  jq -n --arg reason \
    "Blocked: direct push to main/master is not allowed. Create a feature branch and open a PR instead." \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$reason}}'
  exit 0
fi

exit 0
