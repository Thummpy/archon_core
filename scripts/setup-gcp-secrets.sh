#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage: $(basename "$0") --project PROJECT_ID [--help]

Interactive setup for all GCP Secret Manager secrets required by Archon.
Prompts for each secret value, creates or updates the secret.

Required arguments:
  --project    GCP project ID

Exit codes:
  0 — all secrets created/updated
  1 — failure
EOF
}

PROJECT_ID=""

while [ $# -gt 0 ]; do
  case "$1" in
    --project) PROJECT_ID="$2"; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) echo "✗ Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

if [ -z "$PROJECT_ID" ]; then
  echo "✗ --project is required" >&2
  usage
  exit 1
fi

if ! command -v gcloud &>/dev/null; then
  echo "✗ gcloud not found" >&2
  exit 1
fi

create_or_update_secret() {
  local name="$1"
  local value="$2"

  if gcloud secrets describe "$name" --project="$PROJECT_ID" &>/dev/null; then
    echo -n "$value" | gcloud secrets versions add "$name" --data-file=- --project="$PROJECT_ID"
    echo "  ✓ Updated ${name}"
  else
    echo -n "$value" | gcloud secrets create "$name" --data-file=- --project="$PROJECT_ID"
    echo "  ✓ Created ${name}"
  fi
}

SECRETS=(
  "archon-chris-claude-oauth-token|Claude OAuth token (sk-ant-oat-...)"
  "archon-chris-github-token|GitHub fine-grained PAT (github_pat_...)"
  "archon-chris-discord-bot-token|Discord bot token"
  "archon-chris-oauth2-client-id|Google OAuth2 Client ID (from GCP Console Credentials)"
  "archon-chris-oauth2-client-secret|Google OAuth2 Client Secret"
)

echo "→ Setting up GCP secrets for project ${PROJECT_ID}"
echo "  Press Enter to skip any secret that's already set."
echo ""

for entry in "${SECRETS[@]}"; do
  IFS='|' read -r name description <<< "$entry"

  existing=""
  if gcloud secrets describe "$name" --project="$PROJECT_ID" &>/dev/null; then
    existing=" [already exists — Enter to keep]"
  fi

  read -r -p "  ${description}${existing}: " value

  if [ -n "$value" ]; then
    create_or_update_secret "$name" "$value"
  elif [ -n "$existing" ]; then
    echo "  ✓ Kept existing ${name}"
  else
    echo "  ⚠ Skipped ${name}"
  fi
done

echo ""
echo "✓ Secret setup complete"
