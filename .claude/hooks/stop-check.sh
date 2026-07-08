#!/bin/bash
set -euo pipefail

MSG="Before finishing: if any changes were made this turn, confirm the narrowest relevant verification command was run and cite the result. If nothing changed, no verification is needed."

jq -n --arg msg "$MSG" \
  '{hookSpecificOutput:{hookEventName:"Stop",additionalContext:$msg}}'
