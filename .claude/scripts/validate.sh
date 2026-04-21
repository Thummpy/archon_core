#!/usr/bin/env bash
# =============================================================================
# Project Validation Script
# =============================================================================
# Runs the full validation suite: lint, type check, unit tests, integration
# tests, and build. Replace each {{COMMAND}} placeholder with the actual
# command for your tech stack during project initialization.
#
# Usage: ./.claude/scripts/validate.sh [--skip-integration]
#
# Graceful null-case handling:
#   - Steps with unresolved {{PLACEHOLDER}} commands are skipped automatically.
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
  if echo "$cmd" | grep -q '{{.*}}'; then
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
  if echo "$path" | grep -q '{{.*}}'; then
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

# Replace the placeholder below with your linter command.
# Examples:
#   Python:     ruff check .
#   Node/TS:    npx eslint .
#   Go:         golangci-lint run
#   Java:       mvn checkstyle:check
run_step "Lint" "{{LINT_COMMAND}}"

# ---------------------------------------------------------------------------
# Step 2: Type Check
# ---------------------------------------------------------------------------
section "Type Check"

# Replace the placeholder below with your type checker command.
# Examples:
#   Python:     mypy src/
#   Node/TS:    npx tsc --noEmit
#   Go:         go vet ./...
#   Java:       (handled by compiler — can skip or use ErrorProne)
run_step "Type Check" "{{TYPE_CHECK_COMMAND}}"

# ---------------------------------------------------------------------------
# Step 3: Unit Tests
# ---------------------------------------------------------------------------
section "Unit Tests"

# Replace the placeholder below with your unit test command.
# Examples:
#   Python:     pytest tests/unit/ -v
#   Node/TS:    npx vitest run --reporter=verbose
#   Go:         go test ./... -short
#   Java:       mvn test -pl unit-tests
#
# Replace {{UNIT_TEST_DIR}} with the test directory (e.g., tests/unit, src/__tests__).
# If your test runner doesn't target a directory (e.g., Go), use run_step instead
# of run_step_if and remove the {{UNIT_TEST_DIR}} line.
run_step_if "{{UNIT_TEST_DIR}}" "Unit Tests" "{{UNIT_TEST_COMMAND}}"

# ---------------------------------------------------------------------------
# Step 4: Integration Tests
# ---------------------------------------------------------------------------
section "Integration Tests"

if [ "$SKIP_INTEGRATION" = true ]; then
  skip_step "Integration Tests"
else
  # Replace the placeholder below with your integration test command.
  # Examples:
  #   Python:     pytest tests/integration/ -v
  #   Node/TS:    npx vitest run --config vitest.integration.config.ts
  #   Go:         go test ./... -run Integration
  #   Java:       mvn verify -pl integration-tests
  #
  # Replace {{INTEGRATION_TEST_DIR}} with the test directory (e.g., tests/integration).
  # If your test runner doesn't target a directory, use run_step instead.
  run_step_if "{{INTEGRATION_TEST_DIR}}" "Integration Tests" "{{INTEGRATION_TEST_COMMAND}}"
fi

# ---------------------------------------------------------------------------
# Step 5: Build
# ---------------------------------------------------------------------------
section "Build"

# Replace the placeholder below with your build command.
# Examples:
#   Python:     python -m build
#   Node/TS:    npm run build
#   Go:         go build ./...
#   Java:       mvn package -DskipTests
run_step "Build" "{{BUILD_COMMAND}}"

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
