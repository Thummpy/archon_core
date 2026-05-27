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

echo "[discord-bot] Token validated, starting bot..." >&2

exec python3 /app/bot.py

# This line only executes if exec fails
echo "ERROR: Failed to exec python3 /app/bot.py" >&2
echo "  Check that python3 and /app/bot.py exist in the container image" >&2
exit 1
