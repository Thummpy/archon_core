#!/usr/bin/env bash
# =============================================================================
# Project Initialization Validator
# =============================================================================
# Validates that all template placeholders have been resolved and required
# files have been populated after the claude.ai brainstorming/init process.
#
# This script performs DETERMINISTIC checks only. For intelligent bootstrapping
# (planning tasks, creating GitHub Issues), run /bootstrap after this passes.
#
# Usage: ./.claude/scripts/init-project.sh
#
# Exit codes:
#   0 — all checks passed, project is ready
#   1 — one or more checks failed
# =============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ERRORS=0
WARNINGS=0

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
error() {
  echo "  ✗ ERROR: $1"
  ERRORS=$((ERRORS + 1))
}

warn() {
  echo "  ⚠ WARN:  $1"
  WARNINGS=$((WARNINGS + 1))
}

pass() {
  echo "  ✓ $1"
}

section() {
  echo ""
  echo "── $1 ──"
}

# ---------------------------------------------------------------------------
# Check 1: Scan for unresolved {{PLACEHOLDER}} markers
# ---------------------------------------------------------------------------
section "Checking for unresolved placeholders"

# Find unresolved placeholders in non-template files
# Excludes: PRP templates, ADR template, reference docs, validate.sh (checked separately)
PLACEHOLDER_HITS=$(grep -rn '{{[A-Z_]*}}' "$REPO_ROOT" \
  --include='*.md' --include='*.json' --include='*.sh' --include='*.yml' --include='*.yaml' \
  --exclude-dir='.git' \
  --exclude-dir='references' \
  --exclude-dir='templates' \
  --exclude-dir='node_modules' \
  | grep -v '.claude/prps/templates/' \
  | grep -v 'INIT_INSTRUCTIONS.md' \
  | grep -v '.claude/scripts/init-project.sh' \
  | grep -v '.claude/scripts/validate.sh' \
  | grep -v '.claude/docs/adr/_template.md' \
  | grep -v '.claude/examples/reference-implementations/' \
  | grep -v '.claude/commands/init.md' \
  || true)

if [ -n "$PLACEHOLDER_HITS" ]; then
  error "Unresolved placeholders found:"
  echo "$PLACEHOLDER_HITS" | while IFS= read -r line; do
    echo "         $line"
  done
else
  pass "No unresolved placeholders"
fi

# ---------------------------------------------------------------------------
# Check 2: CLAUDE.md is populated
# ---------------------------------------------------------------------------
section "Checking .claude/CLAUDE.md"

CLAUDE_FILE="$REPO_ROOT/.claude/CLAUDE.md"
if [ ! -f "$CLAUDE_FILE" ]; then
  error ".claude/CLAUDE.md does not exist"
else
  # Check that the project identity section has been filled in (not just the template header)
  if grep -q '{{PROJECT_NAME}}' "$CLAUDE_FILE"; then
    error ".claude/CLAUDE.md still contains {{PROJECT_NAME}} — project identity not configured"
  else
    pass ".claude/CLAUDE.md project identity is populated"
  fi

  LINE_COUNT=$(wc -l < "$CLAUDE_FILE" | tr -d ' ')
  if [ "$LINE_COUNT" -lt 20 ]; then
    error ".claude/CLAUDE.md appears incomplete ($LINE_COUNT lines — expected at least 20)"
  else
    pass ".claude/CLAUDE.md has content ($LINE_COUNT lines)"
  fi
fi

# ---------------------------------------------------------------------------
# Check 3: PLANNING.md is populated
# ---------------------------------------------------------------------------
section "Checking .claude/PLANNING.md"

PLANNING_FILE="$REPO_ROOT/.claude/PLANNING.md"
if [ ! -f "$PLANNING_FILE" ]; then
  error ".claude/PLANNING.md does not exist"
else
  if grep -q '{{' "$PLANNING_FILE"; then
    error ".claude/PLANNING.md still contains unresolved placeholders"
  else
    pass ".claude/PLANNING.md placeholders resolved"
  fi

  # Check it has more than just headers (at least some content under headers)
  CONTENT_LINES=$(grep -cv '^\s*$\|^#\|^<!--' "$PLANNING_FILE" || true)
  if [ "$CONTENT_LINES" -lt 5 ]; then
    error ".claude/PLANNING.md appears to contain only headers ($CONTENT_LINES content lines)"
  else
    pass ".claude/PLANNING.md has content ($CONTENT_LINES content lines)"
  fi
fi

# ---------------------------------------------------------------------------
# Check 4: settings.local.json has been configured
# ---------------------------------------------------------------------------
section "Checking .claude/settings.local.json"

SETTINGS_FILE="$REPO_ROOT/.claude/settings.local.json"
if [ ! -f "$SETTINGS_FILE" ]; then
  error "settings.local.json does not exist"
else
  if grep -q '{{TECH_STACK_PERMISSIONS}}' "$SETTINGS_FILE"; then
    error "settings.local.json still contains {{TECH_STACK_PERMISSIONS}} — not configured"
  else
    pass "settings.local.json placeholders resolved"
  fi

  if grep -q '"_readme"' "$SETTINGS_FILE"; then
    warn "settings.local.json still contains the _readme key — consider removing it"
  fi
fi

# ---------------------------------------------------------------------------
# Check 5: validate.sh has real commands
# ---------------------------------------------------------------------------
section "Checking .claude/scripts/validate.sh"

VALIDATE_FILE="$REPO_ROOT/.claude/scripts/validate.sh"
if [ ! -f "$VALIDATE_FILE" ]; then
  error ".claude/scripts/validate.sh does not exist"
else
  if grep -q '{{.*}}' "$VALIDATE_FILE"; then
    error ".claude/scripts/validate.sh still contains placeholders — not configured"
  else
    pass "validate.sh placeholders are resolved"
  fi

  if [ ! -x "$VALIDATE_FILE" ]; then
    error ".claude/scripts/validate.sh is not executable (run: chmod +x .claude/scripts/validate.sh)"
  else
    pass "validate.sh is executable"
  fi
fi

# ---------------------------------------------------------------------------
# Check 6: Key directories exist
# ---------------------------------------------------------------------------
section "Checking directory structure"

REQUIRED_DIRS=(
  ".claude/commands"
  ".claude/rules"
  ".claude/docs"
  ".claude/examples/patterns"
  ".claude/examples/reference-implementations"
  ".claude/prps/templates"
  ".claude/docs/adr"
  ".claude/scripts"
  ".githooks"
)

for dir in "${REQUIRED_DIRS[@]}"; do
  if [ -d "$REPO_ROOT/$dir" ]; then
    pass "$dir/ exists"
  else
    error "$dir/ is missing"
  fi
done

# ---------------------------------------------------------------------------
# Check 7: Post-init cleanup reminders
# ---------------------------------------------------------------------------
section "Post-init cleanup"

if [ -f "$REPO_ROOT/INIT_INSTRUCTIONS.md" ]; then
  warn "INIT_INSTRUCTIONS.md still exists — delete it after initialization is complete"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "========================================"
echo "  Init Validation Summary"
echo "========================================"
echo "  Errors:   $ERRORS"
echo "  Warnings: $WARNINGS"
echo "========================================"

if [ "$ERRORS" -gt 0 ]; then
  echo ""
  echo "✗ Validation FAILED — resolve the $ERRORS error(s) above before proceeding."
  echo ""
  echo "Common fixes:"
  echo "  1. Ensure .claude/project_seed.md has been populated (from the claude.ai brainstorming session)"
  echo "  2. Run /init in Claude Code to populate all template files from the seed"
  echo "  3. Re-run this script"
  exit 1
else
  echo ""
  echo "✓ All checks passed. Project is ready."
  echo ""
  echo "Next steps:"
  echo "  1. Run /bootstrap to plan initial tasks and create GitHub Issues"
  echo "  2. Delete INIT_INSTRUCTIONS.md"
  echo "  3. Commit: git commit -m 'feat: initialize project from ai-dev-framework template'"
  echo "  4. Configure GitHub branch protection and CODEOWNERS enforcement"
  echo "  5. Begin development with /plan-feature"
fi
