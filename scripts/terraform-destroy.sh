#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_DIR=$(cd "${SCRIPT_DIR}/.." && pwd)

readonly TERRAFORM_DIR="${PROJECT_DIR}/terraform"

usage() {
  cat <<EOF
Usage: $(basename "$0") [--help]

Destroys all Terraform-managed GCP resources with double confirmation.

Workflow:
  1. Checks required tools (terraform, gcloud)
  2. Runs terraform plan -destroy to preview what will be removed
  3. Requires you to type 'yes' to confirm destruction
  4. Runs terraform destroy

WARNING: This permanently deletes VMs, static IPs, firewall rules, and service
accounts. Data on destroyed VMs is unrecoverable.

Exit codes:
  0 — destroy succeeded
  1 — failure (missing tool, destroy failed, user aborted)
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

main() {
  if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    usage
    exit 0
  fi

  check_deps

  echo "→ Previewing resources to destroy..." >&2
  terraform -chdir="${TERRAFORM_DIR}" plan -destroy

  echo "" >&2
  echo "⚠ This will permanently destroy all Terraform-managed resources." >&2
  echo "  Static IPs will be released. VM data will be lost." >&2
  echo "" >&2
  read -r -p "Type 'yes' to confirm destruction: " confirm
  if [ "$confirm" != "yes" ]; then
    echo "✗ Aborted by user" >&2
    exit 1
  fi

  echo "→ Destroying Terraform-managed resources..." >&2
  if ! terraform -chdir="${TERRAFORM_DIR}" destroy -auto-approve; then
    echo "✗ Terraform destroy failed" >&2
    exit 1
  fi
  echo "✓ All resources destroyed" >&2
}

main "$@"
