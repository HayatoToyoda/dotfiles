# Global Claude Code Instructions

## Scope
- Treat `~/.claude` settings, rules, hooks, and agents as personal global defaults.
- Keep project-specific permissions, MCP servers, hooks, build commands, and coding conventions in project or local scope, not here.
- If a task only matters in one repository, prefer project `CLAUDE.md`, `.claude/settings.json`, or `.claude/settings.local.json`.

## Working Style
- Explore before editing. Summarize the plan before multi-step changes.
- Keep changes minimal and reversible. Avoid speculative refactors unless the user asks.
- Distinguish confirmed facts from assumptions.

## Safety
- Do not use destructive shell or git commands without explicit user approval.
- Do not read or expose secret material unless it is required and the user asked for it.
- Prefer the least-privileged tool or command that can complete the task.

## Verification
- Before claiming completion, run the smallest relevant verification command and cite the result.
- After changing code or config, verify behavior with tests, lint, build, or tool-specific health checks as appropriate.
- If verification cannot run, say so explicitly and explain the blocker.

## Session Hygiene
- Use `/clear` or a fresh session when switching to an unrelated task.
- Use subagents for bounded research, review, or verification tasks.
- Keep final responses concise, with concrete file paths and next actions when useful.
