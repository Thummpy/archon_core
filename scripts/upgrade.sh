#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_DIR=$(cd "${SCRIPT_DIR}/.." && pwd)

readonly COMPOSE_FILE="${PROJECT_DIR}/docker-compose.yml"
readonly CONTAINER_NAME="archon-app"
readonly BACKUP_SCRIPT="${SCRIPT_DIR}/backup.sh"
readonly HEALTH_SCRIPT="${SCRIPT_DIR}/health.sh"
readonly IMAGE_PREFIX="ghcr.io/coleam00/archon"

usage() {
  cat <<EOF
Usage: $(basename "$0") <new-tag> [OPTIONS]

Safely upgrades the pinned Archon Docker image version.

Flow: stop Archon → backup database → update tag in docker-compose.yml →
      docker compose pull → docker compose up -d → validate health

Positional argument:
  <new-tag>    GHCR image tag to upgrade to (e.g., 0.5.0)

Options:
  --dry-run    Show what would happen without modifying anything
  -h, --help   Show this help and exit

Exit codes:
  0  Upgrade successful
  1  Failure — upgrade aborted; docker-compose.yml reverted if pull failed
  2  Health check failed — upgrade applied but Archon is not responding;
     rollback instructions are printed (restore backup before reverting tag)
EOF
}

check_deps() {
  local missing=0
  for cmd in docker sed grep; do
    if ! command -v "${cmd}" &>/dev/null; then
      echo "✗ Required tool not found: ${cmd}" >&2
      case "${cmd}" in
        docker) echo "  Install Docker: https://docs.docker.com/get-docker/" >&2 ;;
        sed)    echo "  sed ships with macOS and most Linux distros" >&2 ;;
        grep)   echo "  grep ships with macOS and most Linux distros" >&2 ;;
      esac
      missing=1
    fi
  done
  if [[ "${missing}" -ne 0 ]]; then
    exit 1
  fi
}

extract_current_tag() {
  local line tag
  line=$(grep "image: ${IMAGE_PREFIX}:" "${COMPOSE_FILE}" || true)
  if [[ -z "${line}" ]]; then
    echo "✗ Could not find image line in ${COMPOSE_FILE}" >&2
    echo "  Expected: image: ${IMAGE_PREFIX}:<tag>" >&2
    exit 1
  fi
  tag="${line##*:}"
  printf '%s\n' "${tag}"
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
  echo "→ Creating pre-upgrade backup..." >&2
  local backup_path
  if ! backup_path=$("${BACKUP_SCRIPT}"); then
    echo "✗ Backup failed — cannot proceed without a backup" >&2
    exit 1
  fi
  echo "✓ Pre-upgrade backup complete: ${backup_path}" >&2
  printf '%s\n' "${backup_path}"
}

update_compose_tag() {
  local new_tag="$1"
  local tmpfile
  tmpfile=$(mktemp)
  echo "→ Updating image tag in docker-compose.yml → ${new_tag}" >&2
  sed "s|image: ${IMAGE_PREFIX}:.*|image: ${IMAGE_PREFIX}:${new_tag}|" \
    "${COMPOSE_FILE}" > "${tmpfile}" && mv "${tmpfile}" "${COMPOSE_FILE}"
  if ! grep -q "image: ${IMAGE_PREFIX}:${new_tag}" "${COMPOSE_FILE}"; then
    echo "✗ Tag update failed — ${IMAGE_PREFIX}:${new_tag} not found after replacement" >&2
    exit 1
  fi
  echo "✓ Image tag updated → ${new_tag}" >&2
}

revert_compose_tag() {
  local old_tag="$1"
  local tmpfile
  tmpfile=$(mktemp)
  echo "→ Reverting image tag in docker-compose.yml → ${old_tag}" >&2
  sed "s|image: ${IMAGE_PREFIX}:.*|image: ${IMAGE_PREFIX}:${old_tag}|" \
    "${COMPOSE_FILE}" > "${tmpfile}" && mv "${tmpfile}" "${COMPOSE_FILE}"
  echo "✓ Image tag reverted → ${old_tag}" >&2
}

pull_image() {
  local old_tag="$1"
  echo "→ Pulling new Archon image from GHCR..." >&2
  if ! docker compose -f "${COMPOSE_FILE}" pull; then
    echo "✗ docker compose pull failed" >&2
    revert_compose_tag "${old_tag}"
    exit 1
  fi
  echo "✓ Image pulled successfully" >&2
}

start_archon() {
  echo "→ Starting Archon..." >&2
  docker compose -f "${COMPOSE_FILE}" up -d
  echo "✓ Archon started" >&2
}

validate_health() {
  echo "→ Validating health..." >&2
  "${HEALTH_SCRIPT}" || return 1
}

print_rollback_instructions() {
  local old_tag="$1"
  local backup_path="$2"
  cat >&2 <<EOF

✗ Health check failed after upgrade. Manual rollback steps:

  1. Stop Archon:
       docker compose down

  2. Restore the database backup:
       cp ${backup_path} ~/archon-data/archon.db

  3. Revert the image tag in docker-compose.yml back to ${old_tag}:
       Open docker-compose.yml and change the image line to:
       image: ${IMAGE_PREFIX}:${old_tag}

  4. Restart Archon:
       docker compose up -d

  5. Verify health:
       scripts/health.sh

WARNING: Always restore the backup (step 2) before reverting the image tag
(step 3). The new version may have modified the database schema on startup.
You can re-run scripts/health.sh manually if Archon needs more startup time.
EOF
}

main() {
  local new_tag="" dry_run=false
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)  usage; exit 0 ;;
      --dry-run)  dry_run=true ;;
      -*)         echo "✗ Unknown flag: $1" >&2; usage >&2; exit 1 ;;
      *)          new_tag="$1" ;;
    esac
    shift
  done
  if [[ -z "${new_tag}" ]]; then
    echo "✗ Missing required argument: <new-tag>" >&2
    usage >&2
    exit 1
  fi
  check_deps
  local old_tag
  old_tag=$(extract_current_tag)
  if [[ "${old_tag}" == "${new_tag}" ]]; then
    echo "✓ Already running ${new_tag} — nothing to do" >&2
    exit 0
  fi
  echo "→ Upgrading Archon: ${old_tag} → ${new_tag}" >&2
  if [[ "${dry_run}" == "true" ]]; then
    echo "  [dry-run] Would stop Archon (${CONTAINER_NAME})" >&2
    echo "  [dry-run] Would back up ~/archon-data/archon.db" >&2
    echo "  [dry-run] Would update docker-compose.yml: ${old_tag} → ${new_tag}" >&2
    echo "  [dry-run] Would pull ${IMAGE_PREFIX}:${new_tag}" >&2
    echo "  [dry-run] Would restart Archon and validate health via scripts/health.sh" >&2
    exit 0
  fi
  stop_archon
  local backup_path
  backup_path=$(run_backup)
  update_compose_tag "${new_tag}"
  pull_image "${old_tag}"
  start_archon
  if ! validate_health; then
    print_rollback_instructions "${old_tag}" "${backup_path}"
    exit 2
  fi
  echo "" >&2
  echo "✓ Upgrade complete: ${old_tag} → ${new_tag}" >&2
  echo "  Backup: ${backup_path}" >&2
}

main "$@"
