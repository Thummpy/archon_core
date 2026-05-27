#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage: $(basename "$0") --project PROJECT_ID --email OAUTH_EMAIL [--help]

One-time setup: creates a GCP service account for GitHub Actions, grants it
the required IAM roles, generates a key, and stores it as a GitHub secret.

Prerequisites:
  - gcloud CLI authenticated as project owner
  - gh CLI authenticated with repo access

Required arguments:
  --project    GCP project ID
  --email      OAuth email (for OAUTH_EMAIL secret)

Exit codes:
  0 — setup complete
  1 — missing tool or failure
EOF
}

check_deps() {
  local missing=0
  for cmd in gcloud gh; do
    if ! command -v "$cmd" &>/dev/null; then
      echo "✗ Required tool not found: $cmd" >&2
      missing=1
    fi
  done
  if [ "$missing" -ne 0 ]; then
    exit 1
  fi
}

PROJECT_ID=""
OAUTH_EMAIL=""

while [ $# -gt 0 ]; do
  case "$1" in
    --project) PROJECT_ID="$2"; shift 2 ;;
    --email) OAUTH_EMAIL="$2"; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) echo "✗ Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

if [ -z "$PROJECT_ID" ] || [ -z "$OAUTH_EMAIL" ]; then
  echo "✗ --project and --email are required" >&2
  usage
  exit 1
fi

check_deps

SA_NAME="archon-ci"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

echo "→ Creating service account ${SA_NAME}..."
if gcloud iam service-accounts describe "$SA_EMAIL" --project="$PROJECT_ID" &>/dev/null; then
  echo "  Already exists, skipping creation"
else
  gcloud iam service-accounts create "$SA_NAME" \
    --display-name="Archon CI — GitHub Actions" \
    --project="$PROJECT_ID"
fi

ROLES=(
  "roles/compute.admin"
  "roles/secretmanager.admin"
  "roles/iam.serviceAccountAdmin"
  "roles/iam.serviceAccountUser"
  "roles/storage.admin"
)

echo "→ Granting IAM roles..."
for role in "${ROLES[@]}"; do
  echo "  → ${role}"
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="$role" \
    --condition=None \
    --quiet >/dev/null
done
echo "✓ IAM roles granted"

KEY_FILE=$(mktemp)
echo "→ Creating service account key..."
gcloud iam service-accounts keys create "$KEY_FILE" \
  --iam-account="$SA_EMAIL" \
  --project="$PROJECT_ID"

echo "→ Setting GitHub secrets..."
gh secret set GCP_SA_KEY < "$KEY_FILE"
echo -n "$PROJECT_ID" | gh secret set GCP_PROJECT_ID
echo -n "$OAUTH_EMAIL" | gh secret set OAUTH_EMAIL
echo "✓ GitHub secrets set: GCP_SA_KEY, GCP_PROJECT_ID, OAUTH_EMAIL"

rm -f "$KEY_FILE"
echo ""
echo "✓ CI setup complete. Trigger the Infrastructure workflow from GitHub Actions."
