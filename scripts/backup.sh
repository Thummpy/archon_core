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

Copies ~/archon-data/archon.db to backups/archon-YYYYMMDD-HHMMSS.db (UTC timestamp).

WARNING: For a consistent backup of a running Archon instance, stop the container
first: docker compose down. This script does not stop the container and does not
copy WAL/SHM sidecar files. Callers such as upgrade.sh and sync-up.sh already
run docker compose down before invoking this script.

Stdout contract:
  On success, prints the absolute path of the created backup to stdout.
  All narration (→ / ✓ / ✗ lines) goes to stderr.

Exit codes:
  0 — backup created successfully
  1 — failure (DB missing, copy failed, required tool not found)
EOF
}

check_deps() {
  local missing=0
  for cmd in cp mkdir date; do
    if ! command -v "$cmd" &>/dev/null; then
      echo "✗ Required tool not found: ${cmd}" >&2
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

  echo "→ Copying database to ${dest}..." >&2
  if ! cp -p "${SOURCE_DB}" "${dest}"; then
    echo "✗ Backup failed (cp returned non-zero)" >&2
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
