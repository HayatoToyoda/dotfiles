---
name: verify-and-ship
description: Verify the current change end-to-end, simplify it, then open a Pull Request. Use when the user says /verify-and-ship or asks to finish, verify and ship the current work.
disable-model-invocation: true
---

# verify-and-ship

Three-phase finishing move for a change that is believed complete. Modeled on
the verify → simplify → ship loop; each phase gates the next.

## Phase 1 — Verify (end-to-end, not just unit tests)

1. Run the project's test suite (or the narrowest set covering the change).
2. Exercise the change for real, not only through tests:
   - Backend/API: start the service and hit the affected endpoint.
   - Frontend: open the page in a browser and confirm the behavior visually.
   - CLI/script: run it with representative input.
3. If anything fails, fix the root cause and re-verify. Do not continue on red.

## Phase 2 — Simplify

Delegate to the `code-simplifier` subagent: remove dead code, collapse
duplication introduced during iteration, drop debug leftovers. Behavior must
not change — re-run the narrowest test after simplification to prove it.

## Phase 3 — Ship

Invoke the `commit-push-pr` skill. Include the verification evidence
(commands, exit status, key results) in the PR body.

## Gotchas

- Phase 2 is skippable only for one-line or config-only changes; say so
  explicitly when skipping.
- If end-to-end verification is impossible in this environment, state the
  blocker in the PR body instead of implying it was done.
