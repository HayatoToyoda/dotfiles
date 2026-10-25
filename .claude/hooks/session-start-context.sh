#!/bin/bash
set -euo pipefail

BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
UPSTREAM=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || echo "no upstream")
STATUS=$(git status --short 2>/dev/null | head -5 || echo "")

CONTEXT="Git context at session start: branch=${BRANCH}, upstream=${UPSTREAM}"
if [ -n "$STATUS" ]; then
  CONTEXT="${CONTEXT}, uncommitted changes: $(printf '%s' "$STATUS" | tr '\n' ' ')"
fi

jq -n --arg ctx "$CONTEXT" \
  '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$ctx}}'
