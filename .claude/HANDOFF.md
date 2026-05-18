# Handoff — Issue #12: Create upgrade.sh with backup safety

## Goal

Create `scripts/upgrade.sh` that safely upgrades the pinned Archon Docker image
version with pre-upgrade SQLite backup and post-upgrade health validation.

## What Was Done

- **Created** `scripts/upgrade.sh` (212 lines, 12 functions):
  - `stop_archon()` — mirrors sync-up.sh exactly; handles already-stopped gracefully
  - `run_backup()` — calls backup.sh, captures stdout as backup path; **hard-fails** if DB missing (unlike sync-up.sh which tolerates missing DB — you can't upgrade what was never set up)
  - `update_compose_tag()` / `revert_compose_tag()` — portable sed via mktemp/mv (no `sed -i`); update verifies with grep-q after write
  - `pull_image()` — reverts compose file on pull failure (safe: no data touched before pull)
  - `validate_health()` — delegates to health.sh, returns 1 without aborting
  - `print_rollback_instructions()` — numbered 5-step guide with exact backup path and old tag embedded
  - `main()` — full flow with `--dry-run`, idempotent same-version check, explicit exit codes (0/1/2)

## Key Decisions

- **No auto-rollback on health failure** — the new Archon version may have modified DB schema during startup; auto-revert without DB restore would leave inconsistent state. Rollback instructions printed instead (exit code 2).
- **Revert on pull failure only** — pull failure means no new image fetched and no data touched; safe to revert compose file. Contrast with health failure where data may already be modified.
- **Hard backup failure** — unlike sync-up.sh which tolerates a missing DB for first-sync, upgrade.sh exits on backup failure. You cannot safely upgrade without a backup.

## Current State

- `scripts/upgrade.sh` committed, PR created, issue #12 closed
- Validation: 4 passed, 0 failed, 2 skipped
- Shellcheck: 0 warnings

## Next Steps

1. **Issue #13** — Create `docs/UPGRADING.md` and `docs/TROUBLESHOOTING.md`
2. **Issue #19** — Define backup consistency model (cp vs sqlite3 .backup) — may affect upgrade.sh's pre-upgrade backup strategy
3. **Issue #30** — Verify git-pull workflow sharing end-to-end

## Issue Tracker

- #12: closed by PR
