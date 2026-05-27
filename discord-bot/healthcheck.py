import os
import sys
import time

SENTINEL = os.environ.get("DATA_DIR", "/data") + "/bot_healthy"
STALE_SECONDS = 120


def main() -> int:
    if not os.path.exists(SENTINEL):
        return 1
    age = time.time() - os.path.getmtime(SENTINEL)
    if age > STALE_SECONDS:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
