#!/bin/bash
# AI harness dotfiles installer (Claude Code / Codex / Cursor)
#
# Strategy: per-item symlinks, NOT a whole-directory symlink.
# Claude Code writes runtime state and ~/.claude/.credentials.json into
# ~/.claude; linking the whole directory would place those inside this git
# repository (one `git add -A` away from leaking a token). With per-item
# links, only version-controlled config lives in the repo.
#
# Usage: bash install.sh
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
TS="$(date +%Y%m%d%H%M%S)"

log() { printf '%s\n' "$*"; }

# link_item <target> <link>: idempotent symlink with backup of real files.
link_item() {
  local target="$1" link="$2"
  mkdir -p "$(dirname "$link")"
  if [ -L "$link" ]; then
    ln -sfn "$target" "$link"
  elif [ -e "$link" ]; then
    log "  backup: $link -> $link.bak.$TS"
    mv "$link" "$link.bak.$TS"
    ln -s "$target" "$link"
  else
    ln -s "$target" "$link"
  fi
  log "  link:   $link -> $target"
}

# ---------------------------------------------------------------------------
# 0. Migrate from the legacy layout (~/.claude was a symlink to the repo).
#    Runtime state that Claude Code wrote inside the repo directory is moved
#    back into a real ~/.claude.
# ---------------------------------------------------------------------------
if [ -L "$HOME/.claude" ]; then
  log "migrate: replacing whole-directory symlink ~/.claude with per-item links"
  rm "$HOME/.claude"
  mkdir -p "$HOME/.claude"
  shopt -s dotglob nullglob
  for item in "$DOTFILES_DIR/.claude"/*; do
    rel=".claude/$(basename "$item")"
    # Never migrate symlinks that point back inside this repo (repo config).
    if [ -L "$item" ] && [[ "$(readlink -f "$item" 2>/dev/null || true)" == "$DOTFILES_DIR"* ]]; then
      continue
    fi
    # Anything not tracked by git is runtime state -> move it out of the repo.
    if ! git -C "$DOTFILES_DIR" ls-files --error-unmatch "$rel" > /dev/null 2>&1 \
       && [ -z "$(git -C "$DOTFILES_DIR" ls-files "$rel" 2>/dev/null)" ]; then
      log "  move runtime state: $rel -> ~/.claude/"
      mv "$item" "$HOME/.claude/"
    fi
  done
  shopt -u dotglob nullglob
fi
mkdir -p "$HOME/.claude"

# ---------------------------------------------------------------------------
# 1. Claude Code (~/.claude) — config items only
# ---------------------------------------------------------------------------
log "Claude Code:"
for item in CLAUDE.md AGENTS.md settings.json statusline-wrapper.sh rules hooks agents skills; do
  link_item "$DOTFILES_DIR/.claude/$item" "$HOME/.claude/$item"
done

# ---------------------------------------------------------------------------
# 2. Codex (~/.codex + ~/.agents/skills)
#    - Global instructions: ~/.codex/AGENTS.md
#    - Skills: Codex reads ~/.agents/skills and follows symlinked skill dirs,
#      so the Claude skills library is shared as-is.
# ---------------------------------------------------------------------------
log "Codex:"
link_item "$DOTFILES_DIR/shared/AGENTS.md" "$HOME/.codex/AGENTS.md"
link_item "$DOTFILES_DIR/codex/config.toml" "$HOME/.codex/config.toml"
link_item "$DOTFILES_DIR/.claude/skills" "$HOME/.agents/skills"

# ---------------------------------------------------------------------------
# 3. Cursor
#    - Cursor loads skills/agents from ~/.claude automatically (covered above).
#    - ~/.cursor/skills is linked as a fallback discovery path.
#    - Global instructions: paste shared/AGENTS.md into
#      Cursor Settings > Rules > User Rules (see cursor/user-rules.md).
# ---------------------------------------------------------------------------
log "Cursor:"
link_item "$DOTFILES_DIR/.claude/skills" "$HOME/.cursor/skills"
log "  note:   paste shared/AGENTS.md into Cursor Settings > Rules (one-time)"

# ---------------------------------------------------------------------------
# 4. MCP servers (user scope) — keep this set deliberately small: each server
#    costs tool-schema tokens in every session. context7 kills hallucinated
#    library APIs with only two tools. Heavier servers (AWS, Playwright)
#    belong in per-project scope, not here.
# ---------------------------------------------------------------------------
if command -v claude > /dev/null 2>&1; then
  log "MCP:"
  if claude mcp get context7 > /dev/null 2>&1; then
    log "  context7: already registered"
  elif claude mcp add --scope user --transport http context7 https://mcp.context7.com/mcp > /dev/null 2>&1; then
    log "  context7: registered (user scope)"
  else
    log "  context7: registration failed — run manually: claude mcp add --scope user --transport http context7 https://mcp.context7.com/mcp"
  fi
fi

log "done."
