# Handoff — Issue #8: sync-up.sh and sync-down.sh

## Goal
Create two host-run Bash scripts for cross-machine data sync via rclone, enabling the laptop-desktop workflow.

## What Was Done
- Created `scripts/sync-up.sh` (181 lines) — stops Archon, backs up DB, syncs `~/archon-data/` to rclone remote. Defaults to NOT restarting (operator is leaving this machine).
- Created `scripts/sync-down.sh` (223 lines) — stops Archon, pulls rclone remote to `~/archon-data/`, restarts by default (operator just arrived). Requires `--yes` or interactive `YES` confirmation before overwriting local data.
- Both scripts: `set -euo pipefail`, dep checks (docker + rclone with install hints), `RCLONE_REMOTE` fallback chain (shell env, `.env`, `gdrive:archon-data`), remote verification via `rclone listremotes`, `docker compose down` (not stop) before any sync, `--dry-run` passthrough, `--help` self-documentation, narration markers to stderr.
- All static validation passed: `bash -n`, `shellcheck` (zero warnings), executable bits, `--help` grep checks, missing-tool narration check.

## Key Decisions
- Scripts are fully self-contained (no shared lib) — matches project convention where existing scripts share no code.
- `read_env_key()` uses `grep`+`cut` (not `source .env`) to avoid shell metacharacter issues under `set -u`.
- rclone flags use array-based approach for shellcheck compliance.
- sync-up calls `backup.sh` after `docker compose down` (not before) per backup.sh's own usage contract.

## Current State
- PR created on `feat/issue-8-...` branch, auto-closes #8 on merge.
- Live rclone sync tests are operator-only (rclone not installed in agent env). Static validation complete.

## Next Steps
1. **Issue #9** — Write `docs/SYNC-BETWEEN-MACHINES.md` (companion doc for these scripts).
2. **Issue #12** — Create `upgrade.sh` script with backup safety.
3. **Issue #19** — Define backup consistency model (cp vs sqlite3 .backup).
4. Remaining docs: #11 (SHARING-WORKFLOWS + DAILY-USE), #13 (UPGRADING + TROUBLESHOOTING).

## Issue Tracker
- #8: closing via this PR
- #9: open, unblocked — can now reference the delivered scripts
