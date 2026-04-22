# Handoff — 2026-04-22 (Issue #4)

## Goal

Ship `scripts/backup.sh` — the foundational safety primitive that copies `~/archon-data/archon.db` to `backups/archon-YYYYMMDD-HHMMSS.db`. Prerequisite for `upgrade.sh` (#12) and `sync-up.sh`/`sync-down.sh` (#8), which must snapshot the DB before touching state.

## What Was Done

- Created `scripts/backup.sh` (87 lines, executable). Mirrors `health.sh` and `setup-oauth.sh` style: `set -euo pipefail`, `SCRIPT_DIR`/`PROJECT_DIR`, readonly `UPPER_SNAKE_CASE` constants, functions `usage` / `check_deps` / `verify_source_db` / `ensure_backup_dir` / `perform_backup` / `main`, `→`/`✓`/`✗` narration.
- Stdout/stderr contract: narration → stderr, backup path → stdout (enables `dest=$(scripts/backup.sh)`). Matches `setup-oauth.sh:74–112` precedent.
- UTC timestamps via `date -u +%Y%m%d-%H%M%S` (portable across GNU and BSD).
- `cp -p` preserves mode/timestamps; explicit failure branch on non-zero return.
- Self-review (`/review 4`): 17 pass / 2 warnings / 0 fail.
- Validation: `.claude/scripts/validate.sh --skip-integration` passed (lint + compose config + build; unit/integration tests gracefully skipped — not configured yet). `shellcheck` clean.

## Key Decisions

- **Use `cp`, not `sqlite3 .backup`.** Issue #4 spec calls for a plain file copy. The WAL/SHM hot-copy consistency question is explicitly deferred to **Issue #19**. `usage()` warns standalone users; callers (`upgrade.sh`, `sync-*.sh`) take responsibility for `docker compose down` before invoking.
- **No `docker exec`.** Script reads the host-mounted `${HOME}/archon-data/archon.db` directly — works even when Docker is not running.
- **`backups/` created at runtime** via `mkdir -p`. No `.gitkeep`. `.gitignore:126` already excludes the directory.

## Current State

Branch `feat/issue-4-create-backup-sh-script` is being committed and pushed. PR will carry `Closes #4` to auto-close the issue on merge. Browser / live-DB runs verified locally: `--help`, missing-DB failure, happy path (produced `backups/archon-*.db`), and stdout/stderr split all behave correctly.

## Next Steps

1. **Issue #19** — decide `cp` vs `sqlite3 .backup` for project-wide backup consistency. If resolved toward `sqlite3 .backup`, swap the `cp -p` call in `perform_backup()`; isolated change.
2. **Issue #5** — `atyeti-pev.yaml` PEV workflow (priority:high).
3. **Issue #7** — `docs/SETUP.md` (priority:high, blocks team onboarding).
4. **Issue #8** — `sync-up.sh` / `sync-down.sh` (priority:high); will consume `backup.sh` via `dest=$(scripts/backup.sh)`.
5. **Issue #12** — `upgrade.sh` (priority:high); also consumes `backup.sh`.

## Issue Tracker Status

- #4 — pending PR merge (auto-closes via `Closes #4` in PR body).
- #19 — open, high priority; drives any future change to backup mechanism.
