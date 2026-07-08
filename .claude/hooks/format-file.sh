#!/bin/bash
# PostToolUse auto-format hook.
# Instructions in CLAUDE.md are followed probabilistically; a hook formats 100%
# of the time. Quiet and non-blocking by design: never install tools, never
# echo formatter output into the model context (that can burn tens of
# thousands of tokens), never fail the tool call.
set -u

INPUT=$(cat)
FILE_PATH=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')

if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

case "$FILE_PATH" in
  *.ts | *.tsx | *.js | *.jsx | *.mjs | *.cjs | *.json | *.css | *.scss)
    # Use the project's own formatter only, resolved from its repo root.
    DIR=$(dirname "$FILE_PATH")
    if ROOT=$(git -C "$DIR" rev-parse --show-toplevel 2> /dev/null); then
      if [ -x "$ROOT/node_modules/.bin/biome" ]; then
        "$ROOT/node_modules/.bin/biome" format --write "$FILE_PATH" > /dev/null 2>&1 || true
      elif [ -x "$ROOT/node_modules/.bin/prettier" ]; then
        "$ROOT/node_modules/.bin/prettier" --log-level silent --write "$FILE_PATH" > /dev/null 2>&1 || true
      fi
    fi
    ;;
  *.py)
    if command -v ruff > /dev/null 2>&1; then
      ruff format --quiet "$FILE_PATH" > /dev/null 2>&1 || true
    fi
    ;;
  *.sh)
    if command -v shfmt > /dev/null 2>&1; then
      shfmt -w "$FILE_PATH" > /dev/null 2>&1 || true
    fi
    ;;
esac

exit 0
