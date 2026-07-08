---
name: commit-push-pr
description: Commit the current changes, push the feature branch, and open a Pull Request following GitHub Flow. Use when the user says /commit-push-pr or wants to ship a finished change as a PR.
disable-model-invocation: true
---

# commit-push-pr

Ship the current working-tree changes as a Pull Request. Inner-loop workflow:
run it many times a day, so keep every step tight.

## Steps

1. **Review the diff before anything else.** Run `git status` and `git diff`
   (plus `git diff --staged`). Do not include unrelated changes; if the tree
   mixes concerns, stage selectively and say so.
2. **Safety check.** Confirm nothing staged matches secret patterns
   (`.env*`, `*.pem`, `*.key`, credentials). If anything looks sensitive,
   stop and ask.
3. **Commit** with a conventional-commit message in English
   (`feat:` / `fix:` / `chore:` / `docs:` ...). Subject ≤ 72 chars, body
   explains why, not what.
4. **Push** to the current feature branch with `git push -u origin <branch>`.
   Never push to main/master — check-main-push.sh enforces this, but do not
   rely on the hook: verify the branch name first.
5. **Open the PR** with `gh pr create`. Fill the body from the commit(s):
   what was lacking, what this changes, how it was verified.
6. **Share the PR URL** and wait for the user's merge approval. Never merge
   without it.

## Gotchas

- If tests exist and have not run in this session, run the narrowest relevant
  test before step 3 — do not open a PR on a red tree.
- If the branch is behind its base, rebase before pushing (never force-push
  shared branches).
