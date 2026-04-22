#!/usr/bin/env bash
# =============================================================================
# Workflow YAML Validator
# =============================================================================
# Validates every *.yaml / *.yml file under .archon/workflows/:
#   1. Parses without YAML errors (safe-load only — never exec/source).
#   2. Has a non-empty top-level 'description:' field (required by CLAUDE.md
#      for Archon skill discovery and the vscode-archon extension).
#   3. Every top-level 'command:' value references a file that exists under
#      .archon/commands/ (relative to the repo root). This is a shallow check —
#      nested command references inside steps are also traversed.
#
# Parser preference: python3 + PyYAML (safe_load). Falls back to yq if python3
# is unavailable or PyYAML is not installed. Prints install instructions if
# neither is available and exits non-zero.
#
# Usage: ./.claude/scripts/validate-workflow-yaml.sh [--help]
#
# Exit codes:
#   0 — all workflow YAML files are valid (or none exist)
#   1 — one or more files failed validation, or no parser is available
# =============================================================================

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_DIR=$(cd "${SCRIPT_DIR}/../.." && pwd)
WORKFLOWS_DIR="${PROJECT_DIR}/.archon/workflows"
COMMANDS_DIR="${PROJECT_DIR}/.archon/commands"

FAILED=0
PASSED=0

# ---------------------------------------------------------------------------
# Parser detection
# ---------------------------------------------------------------------------
detect_parser() {
  if command -v python3 &>/dev/null && python3 -c 'import yaml' 2>/dev/null; then
    echo "python3"
  elif command -v yq &>/dev/null; then
    echo "yq"
  else
    echo "none"
  fi
}

# ---------------------------------------------------------------------------
# Parser wrappers — all use safe/parse-only modes; no exec or eval of YAML
# ---------------------------------------------------------------------------
parse_yaml() {
  local parser="$1" file="$2"
  case "$parser" in
    python3) python3 -c "import sys, yaml; yaml.safe_load(open(sys.argv[1]))" "$file" ;;
    yq)      yq eval '.' "$file" > /dev/null ;;
  esac
}

get_description() {
  local parser="$1" file="$2"
  case "$parser" in
    python3)
      python3 -c "
import sys, yaml
data = yaml.safe_load(open(sys.argv[1]))
print(data.get('description', '') if isinstance(data, dict) else '')
" "$file"
      ;;
    yq) yq eval '.description // ""' "$file" ;;
  esac
}

get_command_refs() {
  local parser="$1" file="$2"
  case "$parser" in
    python3)
      python3 -c "
import sys, yaml

def find_commands(obj):
    if isinstance(obj, dict):
        if 'command' in obj and isinstance(obj['command'], str):
            print(obj['command'])
        for v in obj.values():
            find_commands(v)
    elif isinstance(obj, list):
        for item in obj:
            find_commands(item)

data = yaml.safe_load(open(sys.argv[1]))
if isinstance(data, dict):
    find_commands(data)
" "$file"
      ;;
    yq) yq eval '.. | select(has("command")) | .command' "$file" 2>/dev/null || true ;;
  esac
}

# ---------------------------------------------------------------------------
# Per-file validation
# ---------------------------------------------------------------------------
validate_file() {
  local parser="$1" file="$2"
  local rel_path="${file#${PROJECT_DIR}/}"
  local file_failed=0

  echo "→ Checking ${rel_path}..."

  if ! parse_yaml "$parser" "$file" 2>/dev/null; then
    echo "  ✗ YAML parse error"
    FAILED=$((FAILED + 1))
    return
  fi

  local description
  description=$(get_description "$parser" "$file" 2>/dev/null || echo "")
  if [ -z "$description" ] || [ "$description" = "null" ]; then
    echo "  ✗ missing or empty top-level 'description:' field"
    file_failed=1
  fi

  while IFS= read -r cmd_ref; do
    [ -z "$cmd_ref" ] || [ "$cmd_ref" = "null" ] && continue
    local cmd_file="${COMMANDS_DIR}/${cmd_ref#/}"
    if [ ! -f "$cmd_file" ]; then
      echo "  ✗ 'command: ${cmd_ref}' references a file that does not exist: ${cmd_file}"
      file_failed=1
    fi
  done < <(get_command_refs "$parser" "$file" 2>/dev/null || true)

  if [ "$file_failed" -eq 0 ]; then
    echo "  ✓ OK"
    PASSED=$((PASSED + 1))
  else
    FAILED=$((FAILED + 1))
  fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
  if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    echo "Usage: $(basename "$0") [--help]"
    echo ""
    echo "Validates *.yaml / *.yml files under .archon/workflows/:"
    echo "  - Parses without YAML errors"
    echo "  - Has a non-empty top-level 'description:' field"
    echo "  - Any 'command:' references resolve to files under .archon/commands/"
    exit 0
  fi

  echo "→ Validating workflow YAML files in ${WORKFLOWS_DIR}..."

  if [ ! -d "${WORKFLOWS_DIR}" ]; then
    echo "⊘ .archon/workflows/ does not exist — skipping"
    exit 0
  fi

  local parser
  parser=$(detect_parser)

  if [ "$parser" = "none" ]; then
    echo "✗ No YAML parser found. Install one of:"
    echo "  python3 + PyYAML:  pip3 install pyyaml"
    echo "  yq:                brew install yq"
    exit 1
  fi

  echo "→ Using parser: ${parser}"

  local files=()
  while IFS= read -r -d $'\0' f; do
    files+=("$f")
  done < <(find "${WORKFLOWS_DIR}" -maxdepth 1 \( -name "*.yaml" -o -name "*.yml" \) -print0 2>/dev/null || true)

  if [ "${#files[@]}" -eq 0 ]; then
    echo "⊘ No workflow YAML files found — skipping"
    exit 0
  fi

  for f in "${files[@]}"; do
    validate_file "$parser" "$f"
  done

  echo ""
  echo "========================================"
  echo "  Workflow YAML Validation Summary"
  echo "========================================"
  echo "  Passed: ${PASSED}"
  echo "  Failed: ${FAILED}"
  echo "========================================"

  if [ "${FAILED}" -gt 0 ]; then
    echo ""
    echo "✗ Workflow YAML validation FAILED — ${FAILED} file(s) failed."
    exit 1
  fi

  echo ""
  echo "✓ All workflow YAML files are valid."
  exit 0
}

main "$@"
