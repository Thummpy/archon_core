#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_DIR=$(cd "${SCRIPT_DIR}/.." && pwd)

readonly DATA_DIR="${HOME}/archon-data"
readonly COMPOSE_FILE="${PROJECT_DIR}/docker-compose.yml"
readonly ENV_FILE="${PROJECT_DIR}/.env"
readonly DEFAULT_REMOTE="gdrive:archon-data"
readonly CONTAINER_NAME="archon-app"
readonly BACKUP_SCRIPT="${PROJECT_DIR}/scripts/backup.sh"

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Syncs ~/archon-data → \$RCLONE_REMOTE. Stops Archon first.

Stops Archon (docker compose down) → creates a timestamped backup of
archon.db → syncs ${DATA_DIR} to the configured rclone remote.
Archon stays down after sync by default (--restart to bring it back up).

HARD CONSTRAINT: SQLite does not handle concurrent writers. Archon must
be stopped before sync so the WAL checkpoint completes and the replica
on the remote is consistent.

Options:
  --restart      Bring Archon back up after sync (default: off)
  --no-restart   Do not restart after sync (default)
  --dry-run      Pass --dry-run to rclone; does not transfer files
  -h, --help     Show this help and exit

Environment variables:
  RCLONE_REMOTE  rclone remote:path target (default: ${DEFAULT_REMOTE})
                 Read from: shell env → .env → literal default

Exit codes:
  0  success
  1  any failure (missing tool, misconfigured remote, sync failure)
EOF
}

check_deps() {
  local missing=0
  for cmd in docker rclone; do
    if ! command -v "${cmd}" &>/dev/null; then
      echo "✗ Required tool not found: ${cmd}" >&2
      case "${cmd}" in
        docker) echo "  Install Docker: https://docs.docker.com/get-docker/" >&2 ;;
        rclone) echo "  Install rclone: brew install rclone  (macOS)" >&2
                echo "                  apt-get install rclone  (Linux)" >&2
                echo "                  https://rclone.org/install/" >&2 ;;
      esac
      missing=1
    fi
  done
  if [[ "${missing}" -ne 0 ]]; then
    exit 1
  fi
}

read_env_key() {
  local key="$1"
  [[ ! -f "${ENV_FILE}" ]] && return 0
  local match
  if match=$(grep "^${key}=" "${ENV_FILE}"); then
    printf '%s\n' "${match}" | head -n1 | cut -d'=' -f2-
  fi
}

resolve_remote() {
  if [[ -n "${RCLONE_REMOTE:-}" ]]; then
    printf '%s' "${RCLONE_REMOTE}"
    return 0
  fi
  local env_val
  env_val=$(read_env_key "RCLONE_REMOTE")
  if [[ -n "${env_val}" ]]; then
    printf '%s' "${env_val}"
    return 0
  fi
  printf '%s' "${DEFAULT_REMOTE}"
}

verify_remote() {
  local remote="$1"
  local prefix="${remote%%:*}"
  echo "→ Verifying rclone remote '${prefix}:' is configured..." >&2
  if ! rclone listremotes | grep -q "^${prefix}:$"; then
    echo "✗ rclone remote '${prefix}:' is not configured. Run: rclone config" >&2
    exit 1
  fi
  echo "✓ Remote '${prefix}:' found" >&2
}

stop_archon() {
  echo "→ Stopping Archon (${CONTAINER_NAME}) via docker compose down..." >&2
  local running
  running=$(docker compose -f "${COMPOSE_FILE}" ps -q 2>/dev/null || true)
  if [[ -z "${running}" ]]; then
    echo "✓ Archon already stopped" >&2
    return 0
  fi
  docker compose -f "${COMPOSE_FILE}" down
  echo "✓ Archon stopped" >&2
}

run_backup() {
  echo "→ Creating pre-sync backup..." >&2
  local backup_path
  if backup_path=$("${BACKUP_SCRIPT}"); then
    echo "✓ Pre-sync backup complete: ${backup_path}" >&2
  else
    echo "! No database to back up yet (first sync?). Continuing." >&2
  fi
}

do_sync() {
  local remote="$1"
  local dry_run="$2"
  local start="${SECONDS}"
  local -a flags=(--stats-one-line --stats=5s)
  if [[ "${dry_run}" == "true" ]]; then
    flags+=(--dry-run)
  fi

  echo "→ Syncing ${DATA_DIR} → ${remote}..." >&2
  if ! rclone sync "${DATA_DIR}" "${remote}" "${flags[@]}"; then
    echo "✗ rclone sync failed" >&2
    exit 1
  fi
  local elapsed=$(( SECONDS - start ))
  echo "✓ Sync complete in ${elapsed}s" >&2
}

restart_archon() {
  echo "→ Starting Archon..." >&2
  docker compose -f "${COMPOSE_FILE}" up -d
  echo "→ Validating health..." >&2
  "${PROJECT_DIR}/scripts/health.sh"
}

main() {
  local restart=false
  local dry_run=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --restart)    restart=true ;;
      --no-restart) restart=false ;;
      --dry-run)    dry_run=true ;;
      -h|--help)    usage; exit 0 ;;
      *) echo "✗ Unknown flag: $1" >&2; usage >&2; exit 1 ;;
    esac
    shift
  done

  local script_start="${SECONDS}"

  check_deps

  local remote
  remote=$(resolve_remote)
  echo "→ Remote: ${remote}" >&2

  verify_remote "${remote}"
  stop_archon
  run_backup
  do_sync "${remote}" "${dry_run}"

  if [[ "${restart}" == "true" ]]; then
    restart_archon
  fi

  local elapsed=$(( SECONDS - script_start ))
  echo ""
  echo "✓ sync-up complete in ${elapsed}s → ${remote}"
}

main "$@"
