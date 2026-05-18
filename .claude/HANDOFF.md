# Handoff — Issue #9: Write docs/SYNC-BETWEEN-MACHINES.md

## Goal

Create a beginner-friendly guide for syncing Archon data between machines using rclone and the sync scripts from issue #8.

## What Was Done

- **Created** `docs/SYNC-BETWEEN-MACHINES.md` (259 lines) — full guide covering:
  - Prerequisites, "Why sync?", and "How it works" architecture overview
  - Step-by-step rclone install and Google Drive remote configuration (13-step wizard walkthrough)
  - Optional `RCLONE_REMOTE` configuration in `.env`
  - `sync-up.sh` usage with `--restart` and `--dry-run` flags
  - `sync-down.sh` usage with `--yes`, `--no-restart`, and `--dry-run` flags
  - `--dry-run` for sync-down documented with prompt interaction, side effects, and recommended low-disruption combo (`--dry-run --yes --no-restart`)
  - Common scenarios (leaving laptop, arriving at desktop)
  - "What you should see" output after every procedural step
  - SQLite WAL constraint explained (WHY, not just WHAT)
  - One-directional sync warning, destructive overwrite warning, headless OAuth gotcha

- **Updated** `docs/SETUP.md` line 246 — converted "coming soon" plain-text reference to a proper Markdown link

## Key Decisions

- Documented `--dry-run` for sync-down (not in original PRP) after review identified the gap — especially important since sync-down is destructive and users benefit from previewing
- Noted that `--dry-run` still stops/restarts Archon (script behavior) and recommended the `--dry-run --yes --no-restart` combo for minimal disruption

## Current State

- All changes committed, PR created, issue #9 closed
- Validation: 4 passed, 0 failed, 2 skipped (no unit/integration test dirs yet)

## Next Steps

1. **Issue #12** — Create `upgrade.sh` script with backup safety
2. **Issue #19** — Define backup consistency model (cp vs sqlite3 .backup)
3. Remaining docs: #11 (DAILY-USE), #13 (UPGRADING + TROUBLESHOOTING)

## Issue Tracker

- #9: closed by PR
