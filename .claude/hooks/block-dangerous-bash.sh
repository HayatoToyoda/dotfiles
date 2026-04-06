#!/bin/bash
set -euo pipefail

INPUT=$(cat)
COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
  exit 0
fi

PATTERNS=(
  '(^|[[:space:]])sudo([[:space:]]|$)'
  '(^|[[:space:]])rm([[:space:]]|$).*-[[:alnum:]]*r[[:alnum:]]*.*-[[:alnum:]]*f'
  '(^|[[:space:]])git[[:space:]]+reset[[:space:]]+--hard([[:space:]]|$)'
  '(^|[[:space:]])git[[:space:]]+clean([[:space:]]|$).*-[[:alnum:]]*f.*-[[:alnum:]]*d'
  '(^|[[:space:]])git[[:space:]]+checkout[[:space:]]+--([[:space:]]|$)'
  '(^|[[:space:]])git[[:space:]]+restore([[:space:]]|$).*--source'
  '(^|[[:space:]])git[[:space:]]+push[[:space:]].*--force'
  '(^|[[:space:]])git[[:space:]]+push[[:space:]].*[[:space:]]-f([[:space:]]|$)'
  '(^|[[:space:]])git[[:space:]]+commit[[:space:]].*--amend([[:space:]]|$)'
  '(^|[[:space:]])diskutil[[:space:]]+erase'
  '(^|[[:space:]])mkfs(\.|[[:space:]])'
  '(^|[[:space:]])dd([[:space:]]|$).*if='
  '(^|[[:space:]])shutdown([[:space:]]|$)'
  '(^|[[:space:]])reboot([[:space:]]|$)'
)

for PATTERN in "${PATTERNS[@]}"; do
  if printf '%s\n' "$COMMAND" | grep -Eiq "$PATTERN"; then
    jq -n --arg reason "Blocked potentially destructive Bash command: $COMMAND. Ask the user first and explain why it is necessary." '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$reason}}'
    exit 0
  fi
done

exit 0
