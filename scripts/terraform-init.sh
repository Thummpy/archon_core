#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_DIR=$(cd "${SCRIPT_DIR}/.." && pwd)

readonly TERRAFORM_DIR="${PROJECT_DIR}/terraform"

usage() {
  cat <<EOF
Usage: $(basename "$0") [--help]

Initializes Terraform in the terraform/ directory and validates the configuration.

Checks performed:
  1. Required tools (terraform, gcloud) are installed
  2. GCP application-default credentials are configured
  3. terraform init downloads providers
  4. terraform validate checks configuration syntax

Exit codes:
  0 — initialization and validation succeeded
  1 — missing tool, missing auth, or validation failure
EOF
}

check_deps() {
  local missing=0
  for cmd in terraform gcloud; do
    if ! command -v "$cmd" &>/dev/null; then
      echo "✗ Required tool not found: $cmd" >&2
      case "$cmd" in
        terraform) echo "  Install Terraform: https://developer.hashicorp.com/terraform/install" >&2 ;;
        gcloud)    echo "  Install gcloud SDK: https://cloud.google.com/sdk/docs/install" >&2 ;;
      esac
      missing=1
    fi
  done
  if [ "$missing" -ne 0 ]; then
    exit 1
  fi
}

check_auth() {
  echo "→ Checking GCP application-default credentials..." >&2
  if ! gcloud auth application-default print-access-token &>/dev/null; then
    echo "✗ GCP application-default credentials not configured" >&2
    echo "  Run: gcloud auth application-default login" >&2
    exit 1
  fi
  echo "✓ GCP application-default credentials configured" >&2
}

init_terraform() {
  echo "→ Initializing Terraform in ${TERRAFORM_DIR}..." >&2
  if ! terraform -chdir="${TERRAFORM_DIR}" init; then
    echo "✗ Terraform init failed" >&2
    exit 1
  fi
  echo "✓ Terraform initialized successfully" >&2
}

validate_terraform() {
  echo "→ Validating Terraform configuration..." >&2
  if ! terraform -chdir="${TERRAFORM_DIR}" validate; then
    echo "✗ Terraform validation failed" >&2
    exit 1
  fi
  echo "✓ Terraform configuration is valid" >&2
}

main() {
  if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    usage
    exit 0
  fi

  check_deps
  check_auth
  init_terraform
  validate_terraform
}

main "$@"
