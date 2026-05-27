#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage: $(basename "$0") --host IP --key PATH [--help]

Copies local ~/archon-data/ contents to the GCP VM, replacing remote data.
Stops containers before copy and restarts after.

Required arguments:
  --host    VM IP address (from terraform output instance_ips)
  --key     Path to SSH private key

Exit codes:
  0 — sync complete
  1 — failure
EOF
}

HOST=""
KEY=""
SSH_USER="chris"

while [ $# -gt 0 ]; do
  case "$1" in
    --host) HOST="$2"; shift 2 ;;
    --key) KEY="$2"; shift 2 ;;
    --user) SSH_USER="$2"; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) echo "✗ Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

if [ -z "$HOST" ] || [ -z "$KEY" ]; then
  echo "✗ --host and --key are required" >&2
  usage
  exit 1
fi

LOCAL_DATA="${HOME}/archon-data"
if [ ! -d "$LOCAL_DATA" ]; then
  echo "✗ Local data directory not found: ${LOCAL_DATA}" >&2
  exit 1
fi

echo "→ Stopping containers on VM..."
ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -i "$KEY" \
  "${SSH_USER}@${HOST}" "cd ~/archon_core && docker compose down"

echo "→ Syncing ${LOCAL_DATA}/ to VM..."
scp -o StrictHostKeyChecking=no -i "$KEY" -r \
  "${LOCAL_DATA}"/* "${SSH_USER}@${HOST}:~/archon-data/"

echo "→ Restarting containers on VM..."
ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -i "$KEY" \
  "${SSH_USER}@${HOST}" "cd ~/archon_core && docker compose up -d"

echo "✓ Data synced and containers restarted"
