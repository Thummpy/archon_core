import json
import logging
import os
import time
import uuid

import aiofiles

import config

logger = logging.getLogger("discord-bot.threads")

THREADS_DIR = os.path.join(config.DATA_DIR, "threads")


def _thread_path(thread_id: int) -> str:
    return os.path.join(THREADS_DIR, f"{thread_id}.json")


async def save_context(thread_id: int, messages: list[dict], session_id: str | None = None) -> None:
    os.makedirs(THREADS_DIR, exist_ok=True)
    path = _thread_path(thread_id)
    data = {
        "thread_id": thread_id,
        "session_id": session_id,
        "updated_at": time.time(),
        "message_count": len(messages),
        "messages": messages,
    }
    try:
        async with aiofiles.open(path, "w") as f:
            await f.write(json.dumps(data, indent=2))
    except (OSError, TypeError) as exc:
        logger.error(
            "Failed to save context thread_id=%d error=%s type=%s",
            thread_id,
            exc,
            type(exc).__name__,
        )
        if isinstance(exc, TypeError):
            logger.error(
                "Message structure that failed to serialize: %s",
                str(messages)[:500],
            )
        raise


async def load_context(thread_id: int) -> tuple[list[dict], str | None] | None:
    """Load conversation history and session ID for a thread.

    Returns:
        (messages, session_id): On success. session_id may be None for old threads.
        None: If load failed (corrupt file, I/O error) - signals error to caller.
        ([], None): If thread is new (file doesn't exist) - normal case.
    """
    path = _thread_path(thread_id)
    if not os.path.exists(path):
        return ([], None)
    try:
        async with aiofiles.open(path, "r") as f:
            raw = await f.read()
        data = json.loads(raw)
        messages = data.get("messages", [])
        session_id = data.get("session_id")
        logger.info("Loaded context thread_id=%d message_count=%d session_id=%s", thread_id, len(messages), session_id or "(none)")
        return (messages, session_id)
    except (OSError, json.JSONDecodeError) as exc:
        logger.error(
            "Failed to load context thread_id=%d error=%s path=%s",
            thread_id,
            exc,
            path,
        )
        return None


async def get_or_create_session_id(
    thread_id: int,
    preloaded_result: tuple[list[dict], str | None] | None = None
) -> str | None:
    """Get existing session ID for thread, or create new one.

    Args:
        thread_id: Discord thread ID
        preloaded_result: Optional pre-loaded context from load_context().
                          If provided, skips redundant file load.

    Returns:
        str: Session ID (existing or newly generated UUID)
        None: If load failed (signals error to caller)
    """
    if preloaded_result is not None:
        result = preloaded_result
    else:
        result = await load_context(thread_id)

    if result is None:
        logger.error(
            "Cannot initialize session for thread_id=%d - load_context failed",
            thread_id
        )
        return None
    messages, session_id = result
    if session_id:
        return session_id
    new_session_id = str(uuid.uuid4())
    logger.info("Generated new session session_id=%s thread_id=%d", new_session_id, thread_id)
    return new_session_id


def should_archive(message_count: int) -> bool:
    return message_count >= config.ARCHIVE_THRESHOLD
