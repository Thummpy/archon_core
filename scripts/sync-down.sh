#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_DIR=$(cd "${SCRIPT_DIR}/.." && pwd)

readonly DATA_DIR="${HOME}/archon-data"
readonly COMPOSE_FILE="${PROJECT_DIR}/docker-compose.yml"
readonly ENV_FILE="${PROJECT_DIR}/.env"
readonly DEFAULT_REMOTE="gdrive:archon-data"
readonly CONTAINER_NAME="archon-app"

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Syncs \$RCLONE_REMOTE → ~/archon-data. Stops Archon first, restarts after.

WARNING: This will OVERWRITE ${DATA_DIR} with contents of the remote.
Any local data not yet synced to the remote will be lost.

Stops Archon (docker compose down) → pulls ${DATA_DIR} from the configured
rclone remote → restarts Archon by default. Use --no-restart to keep it down.

Requires --yes or interactive confirmation to protect against accidental
data loss. Pass --yes for non-interactive use (scripts, CI-equivalent).

HARD CONSTRAINT: SQLite does not handle concurrent writers. Archon must
be stopped before sync so the WAL checkpoint completes and the local
data directory is consistent.

Options:
  --yes          Skip interactive confirmation (required for non-TTY use)
  --no-restart   Do not start Archon after sync (default: restart)
  --restart      Start Archon after sync (default)
  --dry-run      Pass --dry-run to rclone; does not transfer files
  -h, --help     Show this help and exit

Environment variables:
  RCLONE_REMOTE  rclone remote:path source (default: ${DEFAULT_REMOTE})
                 Read from: shell env → .env → literal default

Exit codes:
  0  success
  1  any failure (missing tool, misconfigured remote, user declined, sync failure)
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

ensure_data_dir() {
  echo "→ Ensuring data directory exists: ${DATA_DIR}" >&2
  mkdir -p "${DATA_DIR}"
  echo "✓ Data directory ready" >&2
}

confirm_destructive() {
  local remote="$1"
  local auto_yes="$2"

  if [[ "${auto_yes}" == "true" ]]; then
    return 0
  fi

  if [[ ! -t 0 ]]; then
    echo "✗ stdin is not a terminal. Pass --yes to confirm non-interactively." >&2
    exit 1
  fi

  echo "" >&2
  echo "WARNING: This will OVERWRITE ${DATA_DIR} with contents of ${remote}." >&2
  if [[ -f "${DATA_DIR}/archon.db" ]]; then
    local db_size
    db_size=$(du -h "${DATA_DIR}/archon.db" | cut -f1)
    echo "  Local DB: ${DATA_DIR}/archon.db (${db_size})" >&2
  elif [[ -d "${DATA_DIR}" ]]; then
    echo "  Local: ${DATA_DIR} (no archon.db found)" >&2
  else
    echo "  Local: ${DATA_DIR} does not exist yet" >&2
  fi
  echo "" >&2
  printf 'Type YES to proceed: ' >&2
  local answer
  if ! read -r answer; then
    echo "" >&2
    echo "✗ Aborted (no input)." >&2
    exit 1
  fi
  if [[ "${answer}" != "YES" ]]; then
    echo "✗ Aborted." >&2
    exit 1
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

  echo "→ Syncing ${remote} → ${DATA_DIR}..." >&2
  if ! rclone sync "${remote}" "${DATA_DIR}" "${flags[@]}"; then
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
  local auto_yes=false
  local restart=true
  local dry_run=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --yes)        auto_yes=true ;;
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
  confirm_destructive "${remote}" "${auto_yes}"
  stop_archon
  ensure_data_dir
  do_sync "${remote}" "${dry_run}"

  if [[ "${restart}" == "true" ]]; then
    restart_archon
  fi

  local elapsed=$(( SECONDS - script_start ))
  echo ""
  echo "✓ sync-down complete in ${elapsed}s ← ${remote}"
}

main "$@"
