# Handoff — Issue #24 complete (PARTIAL)

## Goal
Verify that workflows authored in the Archon 0.3.6 browser UI write to the host bind-mount at `.archon/workflows/` and survive `docker compose restart app`.

## What Was Done
- Ran live smoke test: UI workflow builder found at `Workflows → + New Workflow → /workflows/builder`.
- **Bind-mount write-back: CONFIRMED.** File `smoke-test.yaml` appeared on host within ~5 seconds of clicking Save.
- **SQLite persistence: UNCONFIRMED.** Save stalled at ~89% — Archon makes an outbound Claude API call during save (model validation/compilation). Call hung, likely expired `CLAUDE_CODE_OAUTH_TOKEN` (see issue #25). SQLite record never written; `/api/workflows` returned `{"workflows":[]}`.
- **Key structural finding:** Archon's UI Workflows page reads from SQLite, not YAML files on disk. Startup log confirms no scan of `/.archon/.archon/workflows/` at boot — only bundled defaults at `/app/.archon/workflows/defaults/` are loaded.
- Filed **issue #30**: verify whether a hand-placed YAML in `.archon/workflows/` appears in Archon's UI after restart (the unverified git-sharing model). Depends on #25 being resolved first.
- Commented on **issue #25** with Test 24 as supporting evidence for Outcome C (expired token).
- Filled Test 24 slot in `.claude/docs/smoke-tests.md`: pending → PARTIAL with full verbatim evidence.
- Updated `docs/WORKFLOW-OVERLAY.md` §1: added two caveats (API call gates save; SQLite is UI source of truth, not YAML files).

## Key Decisions
- PARTIAL (not FAIL): the bind-mount write IS real; the failure was in the API-gated SQLite write blocked by a likely expired token.
- Removed "always restart" blanket note from §1 — misleading for UI-authored workflows where restart can't recover an incomplete save.

## Current State
- PR open on `feat/issue-24-...` → auto-closes #24 on merge.
- Container healthy on port 3000. `archon.db` at `~/archon-data/archon.db`.

## Next Steps
1. **Issue #25** — resolve OAuth token lifetime; fix so Archon can complete outbound API calls during workflow save.
2. **Issue #30** — after #25: hand-place a valid YAML in `.archon/workflows/`, verify it appears in UI after restart. Use bundled schema (`model: sonnet`, block-style `nodes:`).
3. **Issue #19** — backup consistency model (cp vs sqlite3 .backup).
4. **Issue #12** — upgrade.sh script.
5. Remaining docs: #11 (SHARING-WORKFLOWS + DAILY-USE), #9 (SYNC-BETWEEN-MACHINES), #13 (UPGRADING + TROUBLESHOOTING).

## Issue Tracker
- #24: closing via this PR
- #25: open, unblocked — Test 24 evidence added as comment
- #30: open, blocks on #25
