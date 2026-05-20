#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_DIR=$(cd "${SCRIPT_DIR}/.." && pwd)

readonly TEST_WORKFLOW_NAME="verify-sharing-test"
readonly TEST_WORKFLOW_PATH="${PROJECT_DIR}/.archon/workflows/${TEST_WORKFLOW_NAME}.yaml"
readonly DEFAULT_PORT=3000
readonly HEALTH_TIMEOUT=90
readonly HEALTH_INTERVAL=5

# Written by each probe function; read by print_summary.
API_RESULT="not run"
CLI_RESULT="not run"
MOUNT_RESULT="not run"

cleanup() {
  echo ""
  echo "→ Cleanup: removing test YAML..."
  rm -f "${TEST_WORKFLOW_PATH}"
  if docker info &>/dev/null; then
    echo "→ Cleanup: restarting container to restore pre-test state..."
    docker compose -f "${PROJECT_DIR}/docker-compose.yml" restart app 2>/dev/null || true
    wait_for_health "cleanup" || true
  fi
  echo "✓ Cleanup complete."
}

usage() {
  cat <<EOF
Usage: $(basename "$0") [--help]

Tests whether a hand-placed YAML file in .archon/workflows/ appears in
Archon's Web UI (/api/workflows) and CLI (archon workflow list) after
docker compose restart app. Verifies the git-pull team-sharing model.

Checks performed:
  1. API probe     — GET /api/workflows, search for test workflow name
  2. CLI probe     — archon workflow list inside container, stdout+stderr captured
  3. Bind-mount    — confirm file visible inside container at expected path

Exit codes:
  0 — test ran to completion (PASS/FAIL/PARTIAL reported, not an exit code)
  1 — infrastructure failure (container not running, health timeout)

Environment variables:
  PORT  Host port Archon is bound to (default: ${DEFAULT_PORT})
EOF
}

check_deps() {
  echo "→ Checking prerequisites..."
  local missing=0
  for cmd in docker curl; do
    if ! command -v "$cmd" &>/dev/null; then
      echo "  ✗ Required tool not found: $cmd"
      case "$cmd" in
        docker) echo "    Install: https://docs.docker.com/get-docker/" ;;
        curl)   echo "    Install: brew install curl (macOS) | apt-get install curl (Linux)" ;;
      esac
      missing=1
    fi
  done
  if [ "$missing" -ne 0 ]; then
    exit 1
  fi
  if command -v jq &>/dev/null; then
    echo "  ✓ docker, curl, jq available"
  else
    echo "  ✓ docker, curl available (jq not found — raw JSON output)"
  fi
}

gate_container_healthy() {
  echo "→ Gating on container health before testing..."
  local port="${PORT:-${DEFAULT_PORT}}"
  local ps_output container_line state

  ps_output=$(docker compose -f "${PROJECT_DIR}/docker-compose.yml" ps --format json 2>/dev/null) || ps_output=""
  container_line=$(echo "$ps_output" | grep '"Name":"archon-app"' 2>/dev/null) || container_line=""

  if [ -z "$container_line" ]; then
    echo "  ✗ archon-app: not found (not running)"
    echo "    Start it first: docker compose up -d"
    exit 1
  fi

  state=$(echo "$container_line" | grep -o '"State":"[^"]*"' | cut -d'"' -f4) || state=""

  if [ "${state}" != "running" ]; then
    echo "  ✗ archon-app: not running (state: ${state:-unknown})"
    echo "    Start it first: docker compose up -d"
    exit 1
  fi

  if ! curl -sf --max-time 5 "http://localhost:${port}/api/health" &>/dev/null; then
    echo "  ✗ API health check failed — container running but API not ready"
    echo "    Wait 20s and retry, or check logs: docker compose logs app"
    exit 1
  fi

  echo "  ✓ archon-app running and API healthy"
}

wait_for_health() {
  local label="${1:-}"
  local port="${PORT:-${DEFAULT_PORT}}"
  local url="http://localhost:${port}/api/health"
  local elapsed=0

  echo "→ Waiting for API health${label:+ (${label})}..."
  while [ "$elapsed" -lt "$HEALTH_TIMEOUT" ]; do
    if curl -sf --max-time 5 "$url" &>/dev/null; then
      echo "  ✓ API healthy (${elapsed}s)"
      return 0
    fi
    sleep "${HEALTH_INTERVAL}"
    elapsed=$((elapsed + HEALTH_INTERVAL))
  done

  echo "  ✗ API did not become healthy within ${HEALTH_TIMEOUT}s"
  return 1
}

create_test_workflow() {
  echo "→ Creating test YAML: ${TEST_WORKFLOW_PATH}"
  rm -f "${TEST_WORKFLOW_PATH}"
  cat > "${TEST_WORKFLOW_PATH}" <<'YAML'
name: verify-sharing-test
description: Temporary verification workflow — created by verify-workflow-sharing.sh and removed on exit.
provider: claude
model: sonnet
nodes:
  - id: verify-node
    prompt: |
      This is a placeholder node. This workflow exists only to test whether
      hand-placed YAML files are discovered by Archon after a container restart.
      It is not intended to be run and will be removed automatically on script exit.
YAML
  echo "  ✓ Test YAML written (block-style, model: sonnet)"
}

probe_api() {
  local port="${PORT:-${DEFAULT_PORT}}"
  local url="http://localhost:${port}/api/workflows"
  echo "→ Check 1 — API probe: GET ${url}"

  local response
  if ! response=$(curl -sf --max-time 10 "$url" 2>/dev/null); then
    API_RESULT="FAIL (curl error)"
    echo "  ✗ curl returned non-zero — API unreachable"
    return
  fi

  if command -v jq &>/dev/null; then
    echo "  Response: $(echo "$response" | jq -c '.')"
  else
    echo "  Response: ${response}"
  fi

  if echo "$response" | grep -q "${TEST_WORKFLOW_NAME}"; then
    API_RESULT="PASS"
    echo "  ✓ '${TEST_WORKFLOW_NAME}' found in API response"
  else
    API_RESULT="FAIL"
    echo "  ✗ '${TEST_WORKFLOW_NAME}' not found in API response"
    echo "    UI Workflows page reads from SQLite — hand-placed YAML is not scanned at startup"
  fi
}

probe_cli() {
  echo "→ Check 2 — CLI probe: archon workflow list (inside container)"
  local tmp_stderr cli_stdout="" cli_exit=0
  tmp_stderr=$(mktemp)

  cli_stdout=$(docker compose -f "${PROJECT_DIR}/docker-compose.yml" exec -T app \
    archon workflow list 2>"$tmp_stderr") || cli_exit=$?
  local cli_stderr
  cli_stderr=$(cat "$tmp_stderr" 2>/dev/null || true)
  rm -f "$tmp_stderr"

  echo "  stdout: ${cli_stdout:-(empty)}"
  if [ -n "$cli_stderr" ]; then
    echo "  stderr: ${cli_stderr}"
  fi
  if [ "$cli_exit" -ne 0 ]; then
    echo "  exit code: ${cli_exit}"
  fi

  # Exit code 127 = command not found (POSIX standard for exec failures)
  if [ "$cli_exit" -eq 127 ]; then
    CLI_RESULT="UNAVAILABLE"
    echo "  ✗ CLI command unavailable (exit 127 — binary not found in container PATH)"
    return
  fi

  if echo "${cli_stdout}${cli_stderr}" | grep -qiE \
    "command not found|unknown command|is not a.*command|executable file not found|OCI runtime exec failed"; then
    CLI_RESULT="UNAVAILABLE"
    echo "  ✗ CLI command unavailable (not found / exec failed)"
    return
  fi

  if [ "$cli_exit" -ne 0 ] && [ -z "$cli_stdout" ]; then
    CLI_RESULT="UNAVAILABLE"
    echo "  ✗ CLI command exited ${cli_exit} with no output — may not be supported in this version"
    return
  fi

  if echo "$cli_stdout" | grep -q "${TEST_WORKFLOW_NAME}"; then
    CLI_RESULT="PASS"
    echo "  ✓ '${TEST_WORKFLOW_NAME}' found in CLI output"
  else
    CLI_RESULT="FAIL"
    echo "  ✗ '${TEST_WORKFLOW_NAME}' not found in CLI output"
  fi
}

probe_mount() {
  local container_path="/.archon/workflows/${TEST_WORKFLOW_NAME}.yaml"
  echo "→ Check 3 — Bind-mount: ${container_path} in container"

  if docker compose -f "${PROJECT_DIR}/docker-compose.yml" exec -T app \
    ls "$container_path" &>/dev/null 2>&1; then
    MOUNT_RESULT="PASS"
    echo "  ✓ File confirmed in container filesystem"
  else
    MOUNT_RESULT="FAIL"
    echo "  ✗ File not found in container — bind-mount not working?"
  fi
}

print_summary() {
  echo ""
  echo "══════════════════════════════════════════════════════════════════"
  echo " verify-workflow-sharing.sh — Archon 0.3.12 result"
  echo "══════════════════════════════════════════════════════════════════"
  echo " API (UI data source): ${API_RESULT}"
  echo " CLI:                  ${CLI_RESULT}"
  echo " Bind-mount:           ${MOUNT_RESULT}"
  echo "══════════════════════════════════════════════════════════════════"

  if [ "${API_RESULT}" = "PASS" ] && [ "${CLI_RESULT}" = "PASS" ]; then
    echo " Classification: PASS — workflow visible in both UI (API) and CLI"
  elif [ "${API_RESULT}" = "PASS" ] || [ "${CLI_RESULT}" = "PASS" ]; then
    echo " Classification: PARTIAL — one channel sees the workflow, other does not"
  else
    echo " Classification: FAIL — hand-placed YAML not visible via API or CLI"
  fi

  echo ""
  echo " Record this output verbatim in .claude/docs/smoke-tests.md (Test 30)."
}

main() {
  if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    usage
    exit 0
  fi

  trap cleanup EXIT

  check_deps
  gate_container_healthy
  create_test_workflow

  echo "→ Restarting container to simulate git-pull workflow discovery..."
  docker compose -f "${PROJECT_DIR}/docker-compose.yml" restart app
  wait_for_health "post-restart" || {
    echo "✗ Container did not become healthy after restart — aborting test"
    exit 1
  }

  probe_api
  probe_cli
  probe_mount
  print_summary
}

main "$@"
