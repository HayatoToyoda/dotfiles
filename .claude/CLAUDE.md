@AGENTS.md

# Claude Code Specific Instructions

The file above is the canonical cross-tool instruction set (shared with Codex and Cursor).
Everything below applies to Claude Code only.

## Session Hygiene

- Use `/clear` or a fresh session when switching to an unrelated task.
- Delegate bounded research, review, and verification to the `investigator`, `reviewer`, and `verifier` subagents to keep the main context clean.
- Keep final responses concise, with concrete file paths and next actions when useful.

## Configuration Scope

- Treat `~/.claude` (settings, rules, hooks, agents, skills) as personal global defaults.
- If something only matters in one repository, put it in that repo's `CLAUDE.md`, `.claude/settings.json`, or `.claude/settings.local.json` instead of here.
