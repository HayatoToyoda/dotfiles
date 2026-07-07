#!/bin/bash
set -euo pipefail

INPUT=$(cat)
COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
  exit 0
fi

deny() {
  jq -n --arg reason "Blocked potentially destructive Bash command: $COMMAND. Ask the user first and explain why it is necessary." \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$reason}}'
  exit 0
}

# --- rm: block recursive+force in any spelling -------------------------------
# Catches: rm -rf / rm -fr / rm -r -f / rm -f -r / rm --recursive --force,
# also when wrapped as `sudo rm`, `xargs rm`, `find ... -exec rm ...`.
if printf '%s\n' "$COMMAND" | grep -Eq '(^|[[:space:];&|])rm[[:space:]]'; then
  HAS_R=false
  HAS_F=false
  printf '%s\n' "$COMMAND" | grep -Eq '(^|[[:space:]])(-[[:alnum:]]*[rR][[:alnum:]]*|--recursive)([[:space:]]|$)' && HAS_R=true
  printf '%s\n' "$COMMAND" | grep -Eq '(^|[[:space:]])(-[[:alnum:]]*f[[:alnum:]]*|--force)([[:space:]]|$)' && HAS_F=true
  if $HAS_R && $HAS_F; then
    deny
  fi
fi

# --- other destructive patterns ----------------------------------------------
PATTERNS=(
  '(^|[[:space:]])sudo([[:space:]]|$)'
  '(^|[[:space:]])git[[:space:]]+reset[[:space:]]+--hard([[:space:]]|$)'
  '(^|[[:space:]])git[[:space:]]+clean([[:space:]]|$).*-[[:alnum:]]*[fd]'
  '(^|[[:space:]])git[[:space:]]+checkout[[:space:]]+--([[:space:]]|$)'
  '(^|[[:space:]])git[[:space:]]+restore([[:space:]]|$).*--source'
  '(^|[[:space:]])git[[:space:]]+push[[:space:]].*--force'
  '(^|[[:space:]])git[[:space:]]+push[[:space:]].*[[:space:]]-f([[:space:]]|$)'
  '(^|[[:space:]])git[[:space:]]+commit[[:space:]].*--amend([[:space:]]|$)'
  '(^|[[:space:]])git[[:space:]]+branch[[:space:]].*-[[:alnum:]]*D'
  '(^|[[:space:]])diskutil[[:space:]]+erase'
  '(^|[[:space:]])mkfs(\.|[[:space:]])'
  '(^|[[:space:]])dd([[:space:]]|$).*of=/dev/'
  '(^|[[:space:]])shutdown([[:space:]]|$)'
  '(^|[[:space:]])reboot([[:space:]]|$)'
  '(^|[[:space:]])chmod[[:space:]]+(-[[:alnum:]]+[[:space:]]+)*777([[:space:]]|$)'
  '>[[:space:]]*/dev/sd[a-z]'
)

for PATTERN in "${PATTERNS[@]}"; do
  if printf '%s\n' "$COMMAND" | grep -Eiq "$PATTERN"; then
    deny
  fi
done

exit 0
