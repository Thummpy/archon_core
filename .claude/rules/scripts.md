---
paths:
  - "scripts/**"
  - "**/*.sh"
---

# Script Conventions

## Structure

- Every script starts with `#!/usr/bin/env bash` and `set -euo pipefail`.
- Check for required tools (docker, rclone, claude, gh, jq) at the top and print install instructions if missing.
- All scripts are idempotent — handle "already done" gracefully, do not fail on re-run.
- All scripts narrate — print what they are about to do before doing it (`echo "→ ..."`).
- Exit non-zero on failure with a human-readable error message.

## Naming

- Script files: lowercase-with-hyphens (e.g., `setup-oauth.sh`, `sync-up.sh`).
- Shell functions: `lower_snake_case`.
- Local variables: `lower_snake_case`.
- Constants and environment variables: `UPPER_SNAKE_CASE`.

## Backup Convention

- Backup files go in the `backups/` directory (`.gitignore`'d).
- Timestamp naming: `archon-YYYYMMDD-HHMMSS.db`.
