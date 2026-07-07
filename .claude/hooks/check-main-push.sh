#!/bin/bash
set -euo pipefail

INPUT=$(cat)
COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty')
CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // empty')

[ -z "$COMMAND" ] && exit 0

deny() {
  jq -n --arg reason \
    "Blocked: direct push to main/master is not allowed. Create a feature branch and open a PR instead." \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$reason}}'
  exit 0
}

is_protected() {
  case "${1##*:}" in                       # src:dst -> dst, plain ref -> itself
    main|master|refs/heads/main|refs/heads/master) return 0 ;;
  esac
  return 1
}

current_branch_protected() {
  [ -n "$CWD" ] && command -v git > /dev/null 2>&1 || return 1
  case "$(git -C "$CWD" branch --show-current 2>/dev/null)" in
    main|master) return 0 ;;
  esac
  return 1
}

# Inspect each shell segment separately so `cmd A; git push origin main` is caught.
while IFS= read -r SEG; do
  # Must be a real `git [opts] push` (excludes e.g. `git stash push`).
  printf '%s\n' "$SEG" | grep -Eq '(^|[[:space:]])git[[:space:]]+(-[^[:space:]]+[[:space:]]+)*push([[:space:]]|$)' || continue

  # Collect non-option tokens after `push`: first is the remote, the rest are refspecs.
  # Known limitation: `git -C <path> push` style global options with separate
  # arguments other than -C/-c are not parsed; AGENTS.md guidance still applies.
  ARGS=$(printf '%s\n' "$SEG" | awk '{
    gitseen=0; collect=0;
    for (i=1; i<=NF; i++) {
      if (collect) { if ($i !~ /^-/) print $i; continue }
      if ($i == "git") { gitseen=1; continue }
      if (gitseen && ($i == "-C" || $i == "-c")) { i++; continue }
      if (gitseen && $i ~ /^-/) { continue }
      if (gitseen && $i == "push") { collect=1; continue }
      gitseen=0
    }
  }')

  COUNT=$(printf '%s\n' "$ARGS" | grep -c . || true)
  if [ "$COUNT" -ge 2 ]; then
    while IFS= read -r SPEC; do
      is_protected "$SPEC" && deny
    done <<< "$(printf '%s\n' "$ARGS" | tail -n +2)"
  else
    # `git push` or `git push origin`: pushes the current branch.
    current_branch_protected && deny
  fi
done <<< "$(printf '%s\n' "$COMMAND" | tr ';|&' '\n')"

exit 0
