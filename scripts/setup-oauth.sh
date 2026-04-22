#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_DIR=$(cd "${SCRIPT_DIR}/.." && pwd)

readonly ENV_FILE="${PROJECT_DIR}/.env"
readonly ENV_EXAMPLE="${PROJECT_DIR}/.env.example"
readonly ENV_KEY="CLAUDE_CODE_OAUTH_TOKEN"

usage() {
  cat <<EOF
Usage: $(basename "$0") [--help]

Runs 'claude setup-token' to generate a long-lived OAuth token and
writes it into .env as ${ENV_KEY}.

Safe to re-run — each invocation generates a fresh token and updates .env
without overwriting other keys (PORT, RCLONE_REMOTE, etc.).

Requirements:
  - claude CLI on PATH
    Install: curl -fsSL https://claude.ai/install.sh | bash
  - A paid Claude plan (Pro, Max, Team, or Enterprise)
  - .env.example must exist at the repo root

Exit codes:
  0 — token written successfully
  1 — a required step failed (see error message)
EOF
}

check_deps() {
  if ! command -v claude &>/dev/null; then
    echo "✗ Required tool not found: claude"
    echo "  Install: curl -fsSL https://claude.ai/install.sh | bash"
    echo "  Then ensure ~/.local/bin is on PATH (re-open your shell if needed)."
    exit 1
  fi
}

verify_repo_preconditions() {
  echo "→ Verifying repository preconditions..."

  if [ ! -f "${ENV_EXAMPLE}" ]; then
    echo "✗ .env.example not found at ${ENV_EXAMPLE}"
    echo "  Ensure you are in the archon-setup repo root."
    exit 1
  fi

  if ! grep -qE '^\.env$' "${PROJECT_DIR}/.gitignore" 2>/dev/null; then
    echo "✗ .env is not listed in .gitignore"
    echo "  Refusing to write credentials to a file that may be committed to version control."
    exit 1
  fi

  echo "✓ Preconditions satisfied"
}

ensure_env_file() {
  echo "→ Checking for .env file..."

  if [ ! -f "${ENV_FILE}" ]; then
    echo "→ .env not found — copying from .env.example..."
    cp "${ENV_EXAMPLE}" "${ENV_FILE}"
    echo "✓ .env created from .env.example"
  else
    echo "✓ .env already exists"
  fi

  chmod 600 "${ENV_FILE}"
}

generate_token() {
  # All narration goes to stderr so the caller can capture only the token on stdout.
  echo "" >&2
  echo "→ Running 'claude setup-token' to generate an OAuth token..." >&2
  echo "  A browser window will open for Claude sign-in." >&2
  echo "  Complete the sign-in in the browser — control returns here when done." >&2
  echo "  If the browser does not open automatically, follow the URL printed below." >&2
  echo "  Note: a paid Claude plan (Pro, Max, Team, or Enterprise) is required." >&2
  echo "  Re-running this script generates a fresh token (previous token still valid until revoked)." >&2
  echo "" >&2

  local tmpfile
  tmpfile=$(mktemp)
  trap 'rm -f "${tmpfile}"' EXIT

  # Tee to tmpfile for extraction; route tee stdout to stderr so the
  # interactive OAuth prompts/URLs are visible while this function is called
  # inside $() which captures fd 1 only.
  if ! claude setup-token 2>&1 | tee "${tmpfile}" >&2; then
    echo "" >&2
    echo "✗ 'claude setup-token' failed." >&2
    echo "  Ensure you completed the browser sign-in flow and have a paid Claude plan." >&2
    exit 1
  fi

  # Extract the last token-shaped string: opaque alphanumeric, 32+ chars.
  local token
  token=$(grep -oE '[A-Za-z0-9_.-]{32,}' "${tmpfile}" | tail -n1)

  if [ -z "${token}" ]; then
    echo "" >&2
    echo "✗ Token extraction failed — no token-shaped string found in output." >&2
    echo "  Re-run and complete the browser OAuth flow (requires paid Claude plan)." >&2
    exit 1
  fi

  # Return token on stdout for the caller; never echo it in narration.
  printf '%s' "${token}"
}

upsert_env_key() {
  local key="$1"
  local value="$2"
  local file="$3"

  local tmpfile
  tmpfile=$(mktemp "${file}.XXXXXX")

  # Replace existing key line or append if absent.
  if grep -q "^${key}=" "${file}" 2>/dev/null; then
    awk -v key="${key}" -v val="${value}" \
      'BEGIN{FS=OFS="="} $1==key{$0=key"="val} {print}' \
      "${file}" > "${tmpfile}"
  else
    cp "${file}" "${tmpfile}"
    # Ensure file ends with a newline before appending.
    if [ -s "${tmpfile}" ] && [ "$(tail -c1 "${tmpfile}" | wc -c)" -gt 0 ]; then
      printf '\n' >> "${tmpfile}"
    fi
    printf '%s=%s\n' "${key}" "${value}" >> "${tmpfile}"
  fi

  mv "${tmpfile}" "${file}"
  chmod 600 "${file}"
}

main() {
  if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    usage
    exit 0
  fi

  check_deps
  verify_repo_preconditions
  ensure_env_file

  local token
  token=$(generate_token)

  echo ""
  echo "→ Writing ${ENV_KEY} to ${ENV_FILE}..."
  upsert_env_key "${ENV_KEY}" "${token}" "${ENV_FILE}"

  echo "✓ ${ENV_KEY} written to ${ENV_FILE}"
  echo ""
  echo "Next: docker compose up -d"
}

main "$@"
