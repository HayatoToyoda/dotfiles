#!/bin/bash
# Claude Code dotfiles installer
# Usage: bash install.sh
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_SRC="$DOTFILES_DIR/.claude"
CLAUDE_DEST="$HOME/.claude"

if [ -L "$CLAUDE_DEST" ]; then
  echo "既存のシンボリックリンクを更新: $CLAUDE_DEST"
  ln -sfn "$CLAUDE_SRC" "$CLAUDE_DEST"
elif [ -d "$CLAUDE_DEST" ]; then
  BACKUP="$CLAUDE_DEST.bak.$(date +%Y%m%d%H%M%S)"
  echo "既存の ~/.claude をバックアップ: $BACKUP"
  mv "$CLAUDE_DEST" "$BACKUP"
  ln -sfn "$CLAUDE_SRC" "$CLAUDE_DEST"
else
  ln -sfn "$CLAUDE_SRC" "$CLAUDE_DEST"
fi

echo "完了: ~/.claude -> $CLAUDE_SRC"
