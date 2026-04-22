#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_DIR=$(cd "${SCRIPT_DIR}/.." && pwd)
readonly DEFAULT_PORT=3000
readonly HEALTH_ENDPOINT="/api/health"
readonly CONTAINER_NAME="archon-app"

# Global state written by each check function; read by main() for the summary line.
CONTAINER_STATUS="not running"
API_STATUS="unreachable"
WORKFLOW_COUNT="unknown"

usage() {
  cat <<EOF
Usage: $(basename "$0") [--help]

Checks whether the Archon container is running and its API is responding.

Checks performed:
  1. Container status  — is ${CONTAINER_NAME} running? (health gate)
  2. API health        — is ${HEALTH_ENDPOINT} responding? (health gate)
  3. Workflow count    — how many workflows are loaded? (informational only)

Exit codes:
  0 — container is running AND API is responding
  1 — container is down or API is unreachable

Environment variables:
  PORT   Host port Archon is bound to (default: ${DEFAULT_PORT})
EOF
}

check_deps() {
  local missing=0
  for cmd in docker curl; do
    if ! command -v "$cmd" &>/dev/null; then
      echo "✗ Required tool not found: $cmd"
      case "$cmd" in
        docker) echo "  Install Docker: https://docs.docker.com/get-docker/" ;;
        curl)   echo "  Install curl:  brew install curl  (macOS) | apt-get install curl  (Linux)" ;;
      esac
      missing=1
    fi
  done
  if [ "$missing" -ne 0 ]; then
    exit 1
  fi
}

check_container() {
  echo "→ Checking container status (${CONTAINER_NAME})..."

  local ps_output container_line state health
  ps_output=$(docker compose -f "${PROJECT_DIR}/docker-compose.yml" ps --format json 2>/dev/null) || ps_output=""
  container_line=$(echo "$ps_output" | grep "\"Name\":\"${CONTAINER_NAME}\"" 2>/dev/null) || container_line=""

  if [ -z "$container_line" ]; then
    CONTAINER_STATUS="not running"
    echo "✗ ${CONTAINER_NAME}: not running (container not found)"
    return 1
  fi

  state=$(echo "$container_line" | grep -o '"State":"[^"]*"' | cut -d'"' -f4) || state=""
  health=$(echo "$container_line" | grep -o '"Health":"[^"]*"' | cut -d'"' -f4) || health=""

  if [ "${state}" != "running" ]; then
    CONTAINER_STATUS="not running"
    echo "✗ ${CONTAINER_NAME}: not running (state: ${state:-unknown})"
    return 1
  fi

  if [ -n "$health" ]; then
    CONTAINER_STATUS="running (${health})"
    echo "✓ ${CONTAINER_NAME}: running (${health})"
  else
    CONTAINER_STATUS="running"
    echo "✓ ${CONTAINER_NAME}: running"
  fi
}

check_api() {
  local port="${PORT:-${DEFAULT_PORT}}"
  local url="http://localhost:${port}${HEALTH_ENDPOINT}"
  echo "→ Checking API health (${url})..."

  if curl -sf --max-time 5 "$url" &>/dev/null; then
    API_STATUS="OK"
    echo "✓ Archon API: OK"
  else
    API_STATUS="unreachable"
    echo "✗ Archon API: unreachable (${url})"
    return 1
  fi
}

# Informational only — workflow count is never a health gate.
check_workflows() {
  echo "→ Checking loaded workflows..."

  local raw_count
  if raw_count=$(docker compose -f "${PROJECT_DIR}/docker-compose.yml" exec -T app archon workflow list 2>/dev/null | wc -l | tr -d ' '); then
    WORKFLOW_COUNT="${raw_count}"
    echo "  Workflows loaded: ${WORKFLOW_COUNT}"
  else
    WORKFLOW_COUNT="unknown"
    echo "  Workflows loaded: unknown"
  fi
}

main() {
  if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    usage
    exit 0
  fi

  check_deps

  local overall_ok=0
  check_container || overall_ok=1
  check_api || overall_ok=1
  check_workflows

  echo ""
  echo "${CONTAINER_NAME}: ${CONTAINER_STATUS} | Archon API: ${API_STATUS} | Workflows loaded: ${WORKFLOW_COUNT}"

  if [ "$overall_ok" -eq 0 ]; then
    exit 0
  else
    exit 1
  fi
}

main "$@"
