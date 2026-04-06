# Git And Shell Safety

- Never run `git reset --hard`, `git clean -fd`, `git checkout --`, `git restore --source`, or recursive delete commands unless the user explicitly asked for them.
- Prefer non-interactive git commands.
- Review the concrete diff before commit-like actions.
- If a repository already has unrelated changes, do not revert them.
- Keep repo-specific git workflow rules in project scope, not in `~/.claude`.
