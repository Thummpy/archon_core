# Handoff — Issue #23 complete

## Goal
Verify that Archon 0.3.6 actually scans the bind-mount paths declared in docker-compose.yml for user workflow/command overrides.

## What Was Done
- Ran live smoke tests against `ghcr.io/coleam00/archon:0.3.6`.
- Four probes confirmed both `/.archon/.archon/workflows` and `/.archon/.archon/commands` exist, are owned by `appuser`, and appear in Archon's active scan paths.
- Archon's own startup log (`paths_configured: home=/.archon`) proves the doubled-path design is correct and working.
- Created `.claude/docs/smoke-tests.md` — append-only per-tag verification runbook with Test 23 (PASS), Test 24 (pending), Test 25 (pending).
- Added dated verification note to `docs/WORKFLOW-OVERLAY.md` linking to the smoke test evidence.

## Key Decisions
- Smoke test runbook is append-only — prior entries never overwritten; new version sections appended after tag bumps.
- Tests 24 and 25 left as pending with issue refs; they are separate scopes.

## Current State
- Branch `feat/issue-23-...` PR open → auto-closes #23 on merge.
- Archon healthy on port 3000. open-webui on port 3051.
- `~/archon-data/archon.db` is a valid 4KB SQLite file.

## Next Steps
1. **Issue #24** — Verify UI write-back: create a workflow in the Archon web UI at localhost:3000, confirm `.yaml` appears under `.archon/workflows/`, survives `docker compose down/up`.
2. **Issue #25** — Determine `CLAUDE_CODE_OAUTH_TOKEN` lifetime and whether Archon provides auto-refresh.
3. **Issue #19** — Backup consistency model (cp vs sqlite3 .backup).
4. Remaining docs issues: #11, #9, #13.

## Issue Tracker
- #23: closing via this PR
- #24, #25: open, unblocked
