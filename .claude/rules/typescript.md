---
paths: ["**/*.ts", "**/*.tsx"]
---

# TypeScript Rules

Injected only when TypeScript files are touched, so they stay effective
regardless of session length (CLAUDE.md influence decays as context grows).

- Avoid `any`; define proper types. `any` silently disables checking for
  everything it touches, so one `any` can hide bugs far from where it was
  written. Use `unknown` + narrowing when the type is genuinely dynamic.
- Prefer `type` over `interface` unless declaration merging is needed.
  `type` handles unions/intersections uniformly, which keeps the codebase to
  one composition style.
- No non-null assertions (`!`) to silence the checker; handle the null case
  or restructure so it cannot occur. The assertion hides the exact places
  runtime crashes come from.
- Let formatters and linters own style. Do not hand-enforce formatting the
  project's prettier/biome/eslint already handles — fix the config instead.
