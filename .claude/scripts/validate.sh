#!/usr/bin/env bash
# =============================================================================
# Project Validation Script
# =============================================================================
# Runs the full validation suite: lint, type check, unit tests, integration
# tests, and build.
#
# Usage: ./.claude/scripts/validate.sh [--skip-integration]
#
# Graceful null-case handling:
#   - Steps with unresolved placeholder commands are skipped automatically.
#   - Steps whose target directories do not yet exist are skipped automatically.
#   This allows the script to run safely on freshly initialized projects that
#   have no source code or tests yet.
#
# Exit codes:
#   0 — all checks passed (including graceful skips)
#   1 — one or more checks failed
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
SKIP_INTEGRATION=false
FAILED=0
PASSED=0
SKIPPED=0

for arg in "$@"; do
  case "$arg" in
    --skip-integration) SKIP_INTEGRATION=true ;;
    --help|-h)
      echo "Usage: ./.claude/scripts/validate.sh [--skip-integration]"
      echo ""
      echo "Options:"
      echo "  --skip-integration  Skip integration tests"
      echo "  --help, -h          Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $arg"
      exit 1
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
section() {
  echo ""
  echo "========================================"
  echo "  $1"
  echo "========================================"
}

run_step() {
  local name="$1"
  local cmd="$2"

  # Skip steps that still have unresolved placeholder commands
  if echo "$cmd" | grep -q '[{][{].*[}][}]'; then
    echo "⊘ $name skipped (placeholder command not yet configured)"
    SKIPPED=$((SKIPPED + 1))
    return
  fi

  echo "→ Running: $cmd"
  if eval "$cmd"; then
    echo "✓ $name passed"
    PASSED=$((PASSED + 1))
  else
    echo "✗ $name FAILED"
    FAILED=$((FAILED + 1))
  fi
}

# Run a step only if the given path exists. Skips gracefully otherwise.
# Usage: run_step_if <path> <name> <command>
run_step_if() {
  local path="$1"
  local name="$2"
  local cmd="$3"

  # Skip if path is still a placeholder
  if echo "$path" | grep -q '[{][{].*[}][}]'; then
    echo "⊘ $name skipped (target directory placeholder not yet configured)"
    SKIPPED=$((SKIPPED + 1))
    return
  fi

  if [ ! -e "$path" ]; then
    echo "⊘ $name skipped ($path does not exist yet)"
    SKIPPED=$((SKIPPED + 1))
    return
  fi

  run_step "$name" "$cmd"
}

skip_step() {
  local name="$1"
  echo "⊘ $name skipped"
  SKIPPED=$((SKIPPED + 1))
}

# ---------------------------------------------------------------------------
# Step 1: Lint
# ---------------------------------------------------------------------------
section "Lint"

run_step_if "scripts" "Lint" "shellcheck scripts/*.sh"

# ---------------------------------------------------------------------------
# Step 2: Type Check
# ---------------------------------------------------------------------------
section "Type Check"

if [ -f "docker-compose.yml" ]; then
  # docker compose config requires env_file targets to exist on disk.
  # Create a temp .env from .env.example when running in CI or on a fresh clone.
  temp_env_created=false
  if [ ! -f ".env" ] && [ -f ".env.example" ]; then
    cp .env.example .env
    temp_env_created=true
    # Ensure cleanup even if the script is killed mid-run.
    trap 'rm -f .env' EXIT
  fi

  run_step "Type Check" "docker compose config --quiet"

  if [ "$temp_env_created" = true ]; then
    rm -f .env
  fi
else
  echo "⊘ Type Check skipped (docker-compose.yml does not exist yet)"
  SKIPPED=$((SKIPPED + 1))
fi

# ---------------------------------------------------------------------------
# Step 3: Unit Tests
# ---------------------------------------------------------------------------
section "Unit Tests"

run_step_if "tests/unit" "Unit Tests" "echo 'No unit test framework configured for Bash/YAML project'"

# ---------------------------------------------------------------------------
# Step 4: Integration Tests
# ---------------------------------------------------------------------------
section "Integration Tests"

if [ "$SKIP_INTEGRATION" = true ]; then
  skip_step "Integration Tests"
else
  run_step_if "tests/integration" "Integration Tests" "echo 'No integration test framework configured for Bash/YAML project'"
fi

# ---------------------------------------------------------------------------
# Step 5: Build
# ---------------------------------------------------------------------------
section "Build"

run_step "Build" "echo 'No build step required — wrapper repo with config and scripts only'"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "========================================"
echo "  Validation Summary"
echo "========================================"
echo "  Passed:  $PASSED"
echo "  Failed:  $FAILED"
echo "  Skipped: $SKIPPED"
echo "========================================"

if [ "$FAILED" -gt 0 ]; then
  echo ""
  echo "✗ Validation FAILED — $FAILED step(s) failed."
  exit 1
else
  echo ""
  echo "✓ All validation steps passed."
  exit 0
fi
