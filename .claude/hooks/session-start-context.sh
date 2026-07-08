#!/bin/bash
# SessionStart hook: inject the current branch, recent commits, and working
# tree state so every session starts oriented without spending its first
# tool calls on `git status` / `git log`.
set -u

INPUT=$(cat)
CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // empty')

[ -z "$CWD" ] && exit 0
git -C "$CWD" rev-parse --is-inside-work-tree > /dev/null 2>&1 || exit 0

BRANCH=$(git -C "$CWD" branch --show-current 2> /dev/null)
LOG=$(git -C "$CWD" log --oneline -5 2> /dev/null)
STATUS=$(git -C "$CWD" status --short 2> /dev/null | head -20)

CTX="Git context at session start:
branch: ${BRANCH:-(detached HEAD)}
recent commits:
${LOG:-(no commits)}
working tree (git status --short, first 20 lines):
${STATUS:-clean}"

jq -n --arg ctx "$CTX" \
  '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$ctx}}'
