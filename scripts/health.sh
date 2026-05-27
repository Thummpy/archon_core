#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_DIR=$(cd "${SCRIPT_DIR}/.." && pwd)
readonly DEFAULT_PORT=3000
readonly HEALTH_ENDPOINT="/api/health"
readonly WORKFLOWS_ENDPOINT="/api/workflows"
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
  local url="https://localhost${HEALTH_ENDPOINT}"
  echo "→ Checking API health (${url} via Caddy)..."

  local http_code
  if http_code=$(curl -sfk --max-time 5 -o /dev/null -w '%{http_code}' "$url" 2>&1); then
    if [[ "$http_code" == "200" ]]; then
      API_STATUS="OK"
      echo "✓ Archon API: OK (via Caddy reverse proxy)"
    else
      API_STATUS="unreachable"
      echo "✗ Archon API: HTTP ${http_code} (${url})" >&2
      case "$http_code" in
        302) echo "  Hint: OAuth2 Proxy redirecting to login — check OAUTH2_PROXY_* vars in .env" >&2 ;;
        500) echo "  Hint: OAuth2 Proxy internal error — check docker compose logs oauth2-proxy" >&2 ;;
        502|503|504) echo "  Hint: Proxy error — upstream archon-app may not be ready yet" >&2 ;;
      esac
      return 1
    fi
  else
    API_STATUS="unreachable"
    echo "✗ Archon API: connection failed (${url})" >&2
    echo "  Hint: Check 'docker compose ps' — caddy and oauth2-proxy must be running" >&2
    return 1
  fi
}

# Informational only — workflow count is never a health gate.
check_workflows() {
  local url="https://localhost${WORKFLOWS_ENDPOINT}"
  echo "→ Checking loaded workflows (via Caddy)..."

  local response count
  if response=$(curl -sfk --max-time 5 "$url" 2>/dev/null); then
    count=$(printf '%s' "$response" | grep -o '"name":' | wc -l | tr -d ' ') || count="0"
    WORKFLOW_COUNT="${count}"
    echo "  Workflows loaded: ${WORKFLOW_COUNT}"
  else
    WORKFLOW_COUNT="unknown"
    echo "  Workflows loaded: unknown (connection failed — see API health check above)" >&2
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
