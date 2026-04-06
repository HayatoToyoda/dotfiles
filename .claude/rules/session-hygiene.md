# Session Hygiene

- Keep global instructions generic. Repo-specific build, test, deploy, or MCP instructions belong in project scope.
- Split long instructions into small rule files instead of one long global `CLAUDE.md`.
- Clear context before continuing on unrelated work.
- Use subagents with narrow responsibilities for long-running or parallelizable work.
