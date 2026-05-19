# Handoff — Issue #19: Define Backup Consistency Model

## Goal

Replace `cp`-based backup in `scripts/backup.sh` with `sqlite3 .backup` (SQLite Online Backup API) to produce WAL-safe backups regardless of container state. Add ADR documenting the decision.

## What Was Done

- **`scripts/backup.sh`** — replaced `cp -p` with `sqlite3 "${SOURCE_DB}" ".backup '${dest}'"` in `perform_backup()`; updated `check_deps()` to check for `sqlite3` with platform-specific install hints (macOS / Ubuntu/WSL); updated `usage()` to remove the old WAL WARNING and describe WAL-safe behavior.
- **`.claude/docs/adr/0001-backup-consistency-model.md`** — new ADR documenting context (Archon hardcodes WAL mode), decision (sqlite3 Online Backup API), consequences (adds sqlite3 dep, removes live-backup risk), and three rejected alternatives.
- **`.claude/examples/patterns/database-query.md`** — backup pattern updated to `sqlite3 .backup` with a WHY comment explaining WAL safety.
- **`docs/UPGRADING.md`** — WAL paragraph rewritten: backup.sh now handles WAL internally; container still stopped for schema migration safety. Phase 1 and Phase 2 expected-output narration updated to match.
- **`docs/TROUBLESHOOTING.md`** — new "sqlite3 not found" section added (symptom matches `check_deps()` output exactly; platform-specific fix instructions).

## Key Decisions

- **sqlite3 .backup syntax** — uses single-quote wrapping: `".backup '${dest}'"`. The sqlite3 dot-command parser handles quoted filenames, making paths with spaces safe. The PRP explicitly specified this form.
- **Container stop rationale in docs** — changed from "WAL checkpoint safety" to "schema migration safety" throughout UPGRADING.md. Both are true; the new backup mechanism removes the WAL dependency, leaving schema safety as the sole remaining reason.
- **upgrade.sh and sync-up.sh unchanged** — callers continue to stop the container first for their own reasons and capture backup.sh's stdout path. No caller changes required.

## Current State

Issue #19 complete. Validation passed (shellcheck, docker compose config). PR created; branch auto-deletes on merge.

## Next Steps

1. **Issue #30** — Verify git-pull workflow sharing end-to-end (CLI vs UI discrepancy)

## Issue Tracker

- #19: closed via PR (auto-closes on merge via `Closes #19` in PR body)
