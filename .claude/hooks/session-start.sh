#!/bin/bash
# Injected as conversation context at session start (SessionStart hook).
set -euo pipefail

printf "Today: %s\n" "$(date '+%Y-%m-%d %H:%M %Z')"

if git rev-parse --git-dir >/dev/null 2>&1; then
  BRANCH=$(git branch --show-current 2>/dev/null || echo "(detached HEAD)")
  ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
  printf "Repo: %s  Branch: %s\n" "$ROOT" "$BRANCH"
fi
