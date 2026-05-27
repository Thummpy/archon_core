#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_DIR=$(cd "${SCRIPT_DIR}/.." && pwd)

readonly TERRAFORM_DIR="${PROJECT_DIR}/terraform"

usage() {
  cat <<EOF
Usage: $(basename "$0") [--auto-approve] [--help]

Plans and applies Terraform configuration to provision GCP resources.

Workflow:
  1. Checks required tools (terraform, gcloud)
  2. Runs terraform plan and saves to tfplan
  3. Prompts for confirmation (unless --auto-approve)
  4. Applies the saved plan
  5. Displays instance IPs from terraform output

Options:
  --auto-approve   Skip the confirmation prompt
  --help           Show this help message

Exit codes:
  0 — apply succeeded
  1 — failure (missing tool, plan failed, apply failed, user aborted)
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

plan_terraform() {
  echo "→ Running terraform plan..." >&2
  if ! terraform -chdir="${TERRAFORM_DIR}" plan -out=tfplan; then
    echo "✗ Terraform plan failed" >&2
    exit 1
  fi
  echo "✓ Plan saved to tfplan" >&2
}

apply_terraform() {
  echo "→ Applying Terraform plan..." >&2
  if ! terraform -chdir="${TERRAFORM_DIR}" apply tfplan; then
    echo "✗ Terraform apply failed" >&2
    rm -f "${TERRAFORM_DIR}/tfplan"
    exit 1
  fi
  rm -f "${TERRAFORM_DIR}/tfplan"
  echo "✓ Terraform apply succeeded" >&2
}

show_outputs() {
  echo "" >&2
  echo "→ Instance IPs:" >&2
  if ! terraform -chdir="${TERRAFORM_DIR}" output -json instance_ips 2>&1; then
    echo "  ⚠ Could not retrieve outputs (apply succeeded, but output command failed)" >&2
    echo "  Run manually: cd terraform && terraform output instance_ips" >&2
  fi
}

main() {
  local auto_approve=0

  while [ $# -gt 0 ]; do
    case "$1" in
      --auto-approve) auto_approve=1; shift ;;
      --help|-h) usage; exit 0 ;;
      *) echo "✗ Unknown option: $1" >&2; usage; exit 1 ;;
    esac
  done

  check_deps
  plan_terraform

  if [ "$auto_approve" -eq 0 ]; then
    echo "" >&2
    read -r -p "Apply this plan? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
      echo "✗ Aborted by user" >&2
      rm -f "${TERRAFORM_DIR}/tfplan"
      exit 1
    fi
  fi

  apply_terraform
  show_outputs
}

main "$@"
