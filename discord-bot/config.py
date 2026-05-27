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

DISCORD_SERVER_ID = int(os.environ.get("DISCORD_SERVER_ID", "1509185927505907715"))
DATA_DIR = os.environ.get("DATA_DIR", "/data")
COMMANDS_DIR = os.environ.get("COMMANDS_DIR", "/.claude/commands")

CHANNEL_MAP = {
    "dnd-context": "Thummpy/dnd-context",
}

ARCHIVE_THRESHOLD = 100
CLAUDE_TIMEOUT_SECONDS = 120
