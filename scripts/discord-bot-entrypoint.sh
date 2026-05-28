#!/usr/bin/env bash
set -euo pipefail

# Validate DISCORD_BOT_TOKEN is set
if [ -z "${DISCORD_BOT_TOKEN:-}" ]; then
  echo "ERROR: DISCORD_BOT_TOKEN environment variable is not set." >&2
  echo "Set it in .env to authenticate with Discord API." >&2
  echo "Generate at: https://discord.com/developers/applications" >&2
  exit 1
fi

# Basic token format validation
if ! echo "${DISCORD_BOT_TOKEN}" | grep -qE '^[A-Za-z0-9._-]+$'; then
  echo "ERROR: DISCORD_BOT_TOKEN format appears invalid." >&2
  echo "  Expected: alphanumeric with dots, underscores, hyphens" >&2
  exit 1
fi

# Validate CLAUDE_CODE_OAUTH_TOKEN is set
if [ -z "${CLAUDE_CODE_OAUTH_TOKEN:-}" ]; then
  echo "ERROR: CLAUDE_CODE_OAUTH_TOKEN environment variable is not set." >&2
  echo "Set it in .env or generate with: scripts/setup-oauth.sh" >&2
  exit 1
fi

# Restore .claude.json from backup if missing (shared volume may lose it)
if [ ! -f "$HOME/.claude.json" ]; then
  BACKUP=$(ls -t "$HOME/.claude/backups/.claude.json.backup."* 2>/dev/null | head -1)
  if [ -n "$BACKUP" ]; then
    cp "$BACKUP" "$HOME/.claude.json"
    echo "[discord-bot] Restored .claude.json from backup" >&2
  fi
fi

echo "[discord-bot] Token validated, starting bot..." >&2

exec python3 /app/bot.py

# This line only executes if exec fails
echo "ERROR: Failed to exec python3 /app/bot.py" >&2
echo "  Check that python3 and /app/bot.py exist in the container image" >&2
exit 1
