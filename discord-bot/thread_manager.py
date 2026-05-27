import json
import logging
import os
import time

import aiofiles

import config

logger = logging.getLogger("discord-bot.threads")

THREADS_DIR = os.path.join(config.DATA_DIR, "threads")


def _thread_path(thread_id: int) -> str:
    return os.path.join(THREADS_DIR, f"{thread_id}.json")


async def save_context(thread_id: int, messages: list[dict]) -> None:
    os.makedirs(THREADS_DIR, exist_ok=True)
    path = _thread_path(thread_id)
    data = {
        "thread_id": thread_id,
        "updated_at": time.time(),
        "message_count": len(messages),
        "messages": messages,
    }
    try:
        async with aiofiles.open(path, "w") as f:
            await f.write(json.dumps(data, indent=2))
    except OSError as exc:
        logger.error("Failed to save context thread_id=%d error=%s", thread_id, exc)
        raise


async def load_context(thread_id: int) -> list[dict]:
    path = _thread_path(thread_id)
    if not os.path.exists(path):
        return []
    try:
        async with aiofiles.open(path, "r") as f:
            raw = await f.read()
        data = json.loads(raw)
        return data.get("messages", [])
    except (OSError, json.JSONDecodeError) as exc:
        logger.error(
            "Failed to load context thread_id=%d error=%s, starting fresh",
            thread_id,
            exc,
        )
        return []


def should_archive(message_count: int) -> bool:
    return message_count >= config.ARCHIVE_THRESHOLD
