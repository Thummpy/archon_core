# Handoff — Issue #11: Write docs/SHARING-WORKFLOWS.md and docs/DAILY-USE.md

## Goal

Create two day-to-day operation guides for developers who have completed initial setup: a workflow sharing guide and a daily operations guide.

## What Was Done

- **Created** `docs/SHARING-WORKFLOWS.md` (136 lines) — team git workflow for sharing custom workflows:
  - Prerequisites, how sharing works (git-based model), getting workflows (pull → restart → verify)
  - Contributing workflows (three methods, all referencing WORKFLOW-OVERLAY.md for authoring details)
  - Filename override behavior (same-name precedence, `archon-` prefix convention, stub suppression)
  - CLI vs. Web UI listing caveat (SQLite vs. YAML, issue #30 transparency)
  - 89% save stall documented in troubleshooting section

- **Created** `docs/DAILY-USE.md` (279 lines) — routine operations guide:
  - Start/stop Archon, health checks (`health.sh` + `docker compose ps`), log streaming
  - Listing all 10 built-in workflows with description table
  - Running workflows from CLI with examples (`archon-assist`, `archon-fix-github-issue`) and flag reference
  - Running workflows from Web UI (`localhost:3000`, workflows page, builder)
  - Checking status, resuming failed runs, approve/reject gates
  - Viewing results (terminal streaming, artifacts, PR URLs, worktree isolation)
  - `archon doctor` validation, restart patterns (restart vs. down+up)
  - `docker compose exec app` prefix pattern explained for zero-Docker-knowledge audience

- **Updated** `docs/SETUP.md` line 244 — replaced "coming soon — issue #11" with proper Markdown link to DAILY-USE.md

## Key Decisions

- SHARING-WORKFLOWS.md delegates all overlay technical details to WORKFLOW-OVERLAY.md — focuses strictly on the team git collaboration workflow
- Used generic `<tag>` placeholder in `docker compose ps` example output to avoid stale version references
- Documented issue #30 (git-pull workflow sharing unverified) transparently without claiming verified status

## Current State

- All changes committed, PR created, issue #11 closed
- Validation: 4 passed, 0 failed, 2 skipped

## Next Steps

1. **Issue #13** — Create `docs/UPGRADING.md` (version bump procedure with backup safety)
2. **TROUBLESHOOTING.md** — all 5 docs now link to this planned file; creating it would resolve dead links
3. **Issue #30** — smoke-test git-pull workflow sharing end-to-end

## Issue Tracker

- #11: closed by PR
