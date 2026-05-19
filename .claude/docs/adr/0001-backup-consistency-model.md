# ADR-0001: Backup Consistency Model (sqlite3 .backup vs cp)

## Status

Accepted

## Date

2026-05-19

## Context

Archon's SQLite adapter unconditionally enables WAL mode at startup (`PRAGMA journal_mode = WAL`).
This is hardcoded in upstream source and not configurable by operators.

In WAL mode, recent writes are staged in a sidecar file (`archon.db-wal`) and are only merged into
the main database file (`archon.db`) when all database connections close (a WAL checkpoint). A bare
`cp` of `archon.db` while the container is running copies only the main file — it omits `archon.db-wal`
and `archon.db-shm`. The resulting backup is missing any writes that have not yet been checkpointed,
producing an inconsistent or incomplete snapshot. If the container is stopped before `cp` runs, the
bun:sqlite connection pool closes, the WAL checkpoints automatically, and `cp` becomes safe — but
this makes standalone `backup.sh` usage unsafe unless callers always stop the container first.

The `scripts/backup.sh` script is called by:
- `upgrade.sh` (which stops the container first for schema migration safety)
- `sync-up.sh` (which stops the container first for sync consistency)
- Users running it standalone (no container state guarantee)

## Decision

Replace `cp -p` in `scripts/backup.sh` with `sqlite3 "$SOURCE_DB" ".backup '$dest'"`.

SQLite's Online Backup API (used by the `.backup` dot command) reads the database through the
storage engine layer. It handles WAL checkpointing internally and produces a single, self-contained
`.db` file that is consistent as of the moment the backup completes — regardless of whether the
source database is being actively written to. No sidecar files are required to use the backup.

The output filename and format are unchanged: a single timestamped `.db` file in `backups/`.

## Consequences

**Benefits:**
- Standalone `backup.sh` usage is now safe against a running Archon instance.
- The backup file is always complete — no risk of missing WAL-only writes.
- Callers (`upgrade.sh`, `sync-up.sh`) are unaffected: they continue to stop the container first
  for their own reasons, and their stdout contract (capturing the backup path) is preserved.

**Trade-offs:**
- `sqlite3` becomes an explicit runtime dependency. It ships pre-installed on macOS. On
  Debian/Ubuntu and WSL it requires `sudo apt install sqlite3`. `check_deps()` in `backup.sh`
  now checks for `sqlite3` and prints platform-specific install instructions if missing.

**Constraints introduced:**
- None beyond the new dependency.

## Alternatives Considered

**Keep `cp` with a prominent warning:** Rejected. A warning does not make the backup safe — it only
shifts responsibility to the caller. Silent data loss (missing WAL writes) in a backup is worse than
a dependency requirement.

**Detect container state and conditionally use `cp` or `sqlite3 .backup`:** Rejected. This adds
complexity (a `docker inspect` call, container name coupling) with no benefit — `sqlite3 .backup`
is correct in all cases, including when the container is stopped.

**Checkpoint WAL explicitly before `cp`:** Rejected. This requires an open database connection to
issue `PRAGMA wal_checkpoint(FULL)`, which means `sqlite3` is required anyway. The `.backup` API
is simpler and produces the same result.
