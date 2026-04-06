# Verification Rules

- No completion claim without fresh verification evidence from the current session.
- Choose the narrowest command that proves the change: test, lint, build, CLI health check, or targeted diff inspection.
- After editing config, hooks, or instructions, re-read the written files and run the relevant tool health check when available.
- If verification fails, report the real failure and stop claiming success.
- If no files changed, say that no verification run was needed.
