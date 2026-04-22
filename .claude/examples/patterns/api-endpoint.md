# Bash Script Structure

This project has no API endpoints — it is a Docker wrapper repo. This pattern file documents the standard structure for operational Bash scripts, which are the primary "handlers" in this project.

## Generic Flow

Every script follows this sequence:

1. **Check prerequisites** — verify required tools are installed (docker, rclone, etc.)
2. **Validate input** — check arguments and environment variables
3. **Narrate intent** — print what the script is about to do before doing it
4. **Execute operation** — perform the action (idempotently where possible)
5. **Handle errors** — exit non-zero with a human-readable message on failure

## Script Template

### Bash — Operational Script

```bash
#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# Prerequisites
# ---------------------------------------------------------------------------
require_tool() {
  if ! command -v "$1" &> /dev/null; then
    echo "ERROR: $1 is not installed."
    echo "  Install: $2"
    exit 1
  fi
}

require_tool "docker" "https://docs.docker.com/get-docker/"

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
ARCHON_DATA="${ARCHON_DATA:-$HOME/archon-data}"
BACKUP_DIR="./backups"

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
echo "→ Checking Archon container status..."

if ! docker compose ps --format json | jq -e '.[] | select(.Name == "archon-app")' > /dev/null 2>&1; then
  echo "ERROR: archon-app container is not running."
  echo "  Run: docker compose up -d"
  exit 1
fi

echo "✓ Archon is running."
```

## Error Handling

All scripts use `set -euo pipefail` and provide context on failure:

```bash
set -euo pipefail

backup_database() {
  local timestamp
  timestamp=$(date +%Y%m%d-%H%M%S)
  local dest="backups/archon-${timestamp}.db"

  echo "→ Backing up database to ${dest}..."

  if [ ! -f "${ARCHON_DATA}/archon.db" ]; then
    echo "ERROR: Database not found at ${ARCHON_DATA}/archon.db"
    echo "  Has Archon been started at least once?"
    exit 1
  fi

  mkdir -p backups
  cp "${ARCHON_DATA}/archon.db" "${dest}"
  echo "✓ Backup complete: ${dest}"
}
```

## Idempotency Pattern

Scripts handle "already done" gracefully:

```bash
ensure_data_dir() {
  if [ -d "${ARCHON_DATA}" ]; then
    echo "⊘ Data directory already exists: ${ARCHON_DATA}"
    return
  fi

  echo "→ Creating data directory: ${ARCHON_DATA}"
  mkdir -p "${ARCHON_DATA}"
  echo "✓ Created ${ARCHON_DATA}"
}
```

## Rationale

- **Prerequisite checks** prevent cryptic errors when tools are missing — the target audience may not know to install them.
- **Narration** (`echo "→ ..."`) makes scripts self-documenting for users unfamiliar with shell scripting.
- **Idempotency** means scripts are safe to re-run without side effects, which matches the beginner-friendly philosophy.
