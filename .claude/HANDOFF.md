# Handoff — Issue #13: Write docs/UPGRADING.md and docs/TROUBLESHOOTING.md

## Goal

Create the final two documentation guides to complete the docs/ suite: UPGRADING.md for the version bump procedure and TROUBLESHOOTING.md as the central error resolution resource.

## What Was Done

- **Created** `docs/UPGRADING.md` (260 lines): prerequisites, version pinning model, why backup is mandatory (no-migration constraint + WAL caveat), step-by-step upgrade procedure with `upgrade.sh` (all 6 phases with expected output), exit code 1 vs. exit code 2 scenarios, and 5-step manual rollback with ordering rationale.
- **Created** `docs/TROUBLESHOOTING.md` (350 lines): 11 symptom-first sections (Docker not running, container won't start, API health failing, OAuth expired, database not found, upgrade exit code 2, sync remote not configured, sync other errors, permission denied, workflow missing, bind mount empty). Ends with "Still stuck?" contact section — no self-referencing "Something went wrong?" link.
- **Updated** `docs/SETUP.md` line 247: replaced "coming soon — issue #13" placeholder with a proper markdown link to UPGRADING.md matching the format of surrounding list items.

## Key Decisions

- **TROUBLESHOOTING.md has a minimal prerequisites section** despite the PRP not listing one, because docs-guides.md mandates "What you need before starting" for every doc in docs/. The section is lightweight (repo cloned, terminal in repo root) so it orients without gatekeeping.
- **Upgrade procedure phases shown without explicit "What you should see" labels** — all 6 phases are output from a single `./scripts/upgrade.sh` command, so the expected output is presented as sequential console output under each phase heading. Rollback steps (separate user commands) do use the explicit label.
- **Existing inline troubleshooting left in place** in DAILY-USE.md (lines 260-280) and SHARING-WORKFLOWS.md (lines 124-137) per PRP CRITICAL guidance — TROUBLESHOOTING.md is the comprehensive reference, inline hints stay for contextual quick-fixes.

## Current State

- All files written, reviewed, validated (4 passed, 0 failed, 2 skipped)
- All 5 existing docs' TROUBLESHOOTING.md dead links now resolve
- SETUP.md UPGRADING.md link now resolves
- docs/ suite is complete: SETUP → DAILY-USE → SHARING-WORKFLOWS → SYNC-BETWEEN-MACHINES → UPGRADING → TROUBLESHOOTING + WORKFLOW-OVERLAY

## Next Steps

1. **Issue #19** — Define backup consistency model (cp vs sqlite3 .backup)
2. **Issue #30** — Verify git-pull workflow sharing end-to-end (CLI vs UI discrepancy referenced in TROUBLESHOOTING.md)

## Issue Tracker

- #13: closed by PR
