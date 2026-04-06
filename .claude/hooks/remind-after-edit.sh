#!/bin/bash
set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

MESSAGE="You changed $FILE_PATH. Before finishing, run the smallest relevant verification command and cite the result. Keep repo-specific permissions, hooks, MCP servers, and workflow rules in project or local scope instead of user-global settings."

case "$FILE_PATH" in
  */.claude/*|*/CLAUDE.md|*/AGENTS.md)
    MESSAGE="$MESSAGE After Claude configuration changes, run Claude-specific health checks such as claude doctor, claude plugin list, or other targeted CLI checks when available."
    ;;
esac

case "$FILE_PATH" in
  *.env|*.env.*|*.pem|*.key|*/secrets/*)
    MESSAGE="$MESSAGE Treat this as sensitive material: avoid echoing secret contents and prefer redacted summaries."
    ;;
esac

jq -n --arg message "$MESSAGE" '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$message}}'
