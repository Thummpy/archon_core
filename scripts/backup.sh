#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_DIR=$(cd "${SCRIPT_DIR}/.." && pwd)

readonly SOURCE_DB="${HOME}/archon-data/archon.db"
readonly BACKUP_DIR="${PROJECT_DIR}/backups"
readonly BACKUP_PREFIX="archon"

usage() {
  cat <<EOF
Usage: $(basename "$0") [--help]

Backs up ~/archon-data/archon.db to backups/archon-YYYYMMDD-HHMMSS.db (UTC timestamp).

Uses sqlite3's Online Backup API (.backup command), which handles WAL checkpointing
internally. The backup is consistent even against a running Archon instance — no need
to stop the container first. Callers such as upgrade.sh and sync-up.sh stop the
container before calling this script for other reasons (schema migration safety,
sync consistency), not for backup consistency.

Stdout contract:
  On success, prints the absolute path of the created backup to stdout.
  All narration (→ / ✓ / ✗ lines) goes to stderr.

Exit codes:
  0 — backup created successfully
  1 — failure (DB missing, backup failed, required tool not found)
EOF
}

check_deps() {
  local missing=0
  for cmd in sqlite3 mkdir date; do
    if ! command -v "$cmd" &>/dev/null; then
      echo "✗ Required tool not found: ${cmd}" >&2
      case "${cmd}" in
        sqlite3) echo "  macOS (pre-installed): brew install sqlite3" >&2
                 echo "  Ubuntu/WSL:            sudo apt install sqlite3" >&2 ;;
      esac
      missing=1
    fi
  done
  if [ "$missing" -ne 0 ]; then
    exit 1
  fi
}

verify_source_db() {
  if [[ ! -f "${SOURCE_DB}" ]]; then
    echo "✗ Database not found: ${SOURCE_DB}" >&2
    echo "  Has Archon been started? Try: docker compose up -d" >&2
    exit 1
  fi
  echo "✓ Found database: ${SOURCE_DB}" >&2
}

ensure_backup_dir() {
  echo "→ Ensuring backup directory exists: ${BACKUP_DIR}" >&2
  mkdir -p "${BACKUP_DIR}"
}

perform_backup() {
  local timestamp
  timestamp=$(date -u +%Y%m%d-%H%M%S)
  local dest="${BACKUP_DIR}/${BACKUP_PREFIX}-${timestamp}.db"

  echo "→ Backing up database to ${dest}..." >&2
  if ! sqlite3 "${SOURCE_DB}" ".backup '${dest}'"; then
    echo "✗ Backup failed (sqlite3 returned non-zero)" >&2
    exit 1
  fi

  echo "✓ Backup created: ${dest}" >&2
  printf '%s\n' "${dest}"
}

main() {
  if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    usage
    exit 0
  fi

  check_deps
  verify_source_db
  ensure_backup_dir
  perform_backup
}

main "$@"
