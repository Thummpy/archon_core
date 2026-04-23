# Handoff — 2026-04-22 (Issue #7 — closed)

## Goal

Create `docs/SETUP.md` — the primary first-time setup guide for developers installing Archon,
walking from "Docker not installed" through "Archon running at http://localhost:3000".

## What Was Done

- Created `docs/SETUP.md` (251 lines): 10 steps, Prerequisites, Why Docker?, Next Steps,
  Something went wrong? Follows `docs-guides.md` conventions exactly.
- Updated `README.md:29` — link updated from `.claude/docs/setup.md` → `docs/SETUP.md`
- Replaced `.claude/docs/setup.md` with an 8-line redirect pointer
- Smoke test findings (3 items) documented and woven into SETUP.md prose:
  - Item 1 (volume mount paths): Pass (pre-verified via `bd5ad77` source references)
  - Item 2 (UI write-back): Pass (pre-verified via WORKFLOW-OVERLAY.md + PLANNING.md)
  - Item 3 (OAuth TTL): Outcome A — one-year token, no refresh section needed
- `/review 7`: 21 pass / 3 warnings / 0 failures
- Validation: 4 passed / 0 failed / 2 skipped

## Current State

PR created, issue #7 auto-closes on merge.

## Next Steps

1. **Issue #11** — `docs/DAILY-USE.md` and `docs/SHARING-WORKFLOWS.md` (stub-linked from SETUP.md)
2. **Issue #13** — `docs/UPGRADING.md` and `docs/TROUBLESHOOTING.md` (broken link target in SETUP.md)
3. **Issue #9** — `docs/SYNC-BETWEEN-MACHINES.md` (stub-linked from SETUP.md Next steps)
4. **Issues #23/#24** — Live container smoke tests for volume mount paths and UI write-back

## Issue Tracker Status

- #7 — closed (auto-closes via `Closes #7` in PR body)
- #25 — can be closed; OAuth TTL resolved as Outcome A (one-year token per Anthropic docs)
- #11, #13, #9 — open, unblocked
- #23, #24 — open, independent infrastructure verification
