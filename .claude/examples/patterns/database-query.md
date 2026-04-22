# SQLite Data Management Patterns

This project does not perform direct database queries — SQLite is managed entirely by Archon inside the container. This pattern file documents safe patterns for inspecting, backing up, and restoring the Archon database from the host.

## Inspecting the Database

The SQLite database lives at `~/archon-data/archon.db`. It can be inspected with standard tools while Archon is running (read-only queries are safe):

```bash
# List tables
sqlite3 ~/archon-data/archon.db ".tables"

# Check row counts
sqlite3 ~/archon-data/archon.db "SELECT name, (SELECT COUNT(*) FROM pragma_table_info(name)) as columns FROM sqlite_master WHERE type='table';"

# Export a table to CSV
sqlite3 -header -csv ~/archon-data/archon.db "SELECT * FROM workflows;" > workflows.csv
```

## Backup Pattern

Backups use timestamped filenames in the `backups/` directory (`.gitignore`'d):

```bash
#!/usr/bin/env bash
set -euo pipefail

ARCHON_DATA="${ARCHON_DATA:-$HOME/archon-data}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
DEST="backups/archon-${TIMESTAMP}.db"

mkdir -p backups
cp "${ARCHON_DATA}/archon.db" "${DEST}"
echo "✓ Backup: ${DEST}"
```

## Restore Pattern

Restoring requires stopping Archon first — SQLite does not handle concurrent writers:

```bash
#!/usr/bin/env bash
set -euo pipefail

BACKUP_FILE="$1"
ARCHON_DATA="${ARCHON_DATA:-$HOME/archon-data}"

if [ -z "${BACKUP_FILE}" ]; then
  echo "Usage: restore.sh <backup-file>"
  echo "Available backups:"
  ls -1 backups/archon-*.db 2>/dev/null || echo "  (none)"
  exit 1
fi

echo "→ Stopping Archon..."
docker compose down

echo "→ Restoring ${BACKUP_FILE}..."
cp "${BACKUP_FILE}" "${ARCHON_DATA}/archon.db"

echo "→ Starting Archon..."
docker compose up -d

echo "✓ Restored from ${BACKUP_FILE}"
```

## Cross-Machine Sync Safety

SQLite does not handle concurrent writes. Always stop Archon before syncing:

```bash
# CORRECT — stop first, then sync
docker compose down
rclone sync ~/archon-data/ gdrive:archon-data/
docker compose up -d

# WRONG — syncing while Archon is running risks database corruption
rclone sync ~/archon-data/ gdrive:archon-data/  # BAD: Archon may be writing
```

## Rationale

- **Host-path volume** makes the database a regular file — inspectable, copyable, syncable.
- **Timestamp naming** for backups prevents overwriting and provides a clear history.
- **Stop-before-sync** is a hard constraint because SQLite uses file-level locking. The sync scripts enforce this.
