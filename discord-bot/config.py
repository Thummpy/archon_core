import os
import sys


def _require_env(name: str) -> str:
    value = os.environ.get(name, "").strip()
    if not value:
        print(f"ERROR: {name} environment variable is not set.", file=sys.stderr)
        sys.exit(1)
    return value


DISCORD_BOT_TOKEN = _require_env("DISCORD_BOT_TOKEN")
CLAUDE_CODE_OAUTH_TOKEN = _require_env("CLAUDE_CODE_OAUTH_TOKEN")

try:
    DISCORD_SERVER_ID = int(os.environ.get("DISCORD_SERVER_ID", "1509185927505907715"))
except ValueError as exc:
    print(
        f"ERROR: DISCORD_SERVER_ID must be a valid integer (Discord server ID).",
        file=sys.stderr,
    )
    print(
        f"  Current value: {os.environ.get('DISCORD_SERVER_ID', '(not set)')}",
        file=sys.stderr,
    )
    print(
        f"  Find your server ID: Right-click server icon → Copy Server ID (requires Developer Mode enabled)",
        file=sys.stderr,
    )
    sys.exit(1)
DATA_DIR = os.environ.get("DATA_DIR", "/data")
COMMANDS_DIR = os.environ.get("COMMANDS_DIR", "/.claude/commands")

CHANNEL_MAP = {
    "dnd-context": "Thummpy/dnd-context/source",
}

# Archive threads after 100 messages to prevent excessive context length
ARCHIVE_THRESHOLD = 100
# Claude subprocess timeout (prevents hanging on long-running prompts)
CLAUDE_TIMEOUT_SECONDS = 120
