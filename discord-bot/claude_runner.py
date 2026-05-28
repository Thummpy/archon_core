import asyncio
import logging
import os
import time

import config

logger = logging.getLogger("discord-bot.claude")


async def run_claude(
    prompt: str,
    project_dir: str | None = None,
    session_id: str | None = None,
    is_new_session: bool = False,
) -> dict:
    """Run Claude CLI and return structured result with text.

    Args:
        prompt: The user's message to send to Claude
        project_dir: Working directory for Claude CLI (optional)
        session_id: UUID for session persistence. None = one-off prompt (no session)
        is_new_session: If True, use --session-id (create). If False, use --resume (continue).
                        Ignored when session_id is None.

    Returns:
        dict with keys:
            text: str — the final assistant text (for sending to Discord)
            trace: list[dict] — always empty for now; traces readable from session JSONL files
    """
    env = os.environ.copy()
    env["CLAUDE_CODE_OAUTH_TOKEN"] = config.CLAUDE_CODE_OAUTH_TOKEN

    if session_id:
        if is_new_session:
            cmd = ["claude", "--session-id", session_id, "-p", prompt, "--output-format", "text", "--model", "claude-opus-4-6"]
            logger.info("Creating new Claude session session_id=%s", session_id)
        else:
            cmd = ["claude", "--resume", session_id, "-p", prompt, "--output-format", "text", "--model", "claude-opus-4-6"]
            logger.info("Resuming Claude session session_id=%s", session_id)
    else:
        cmd = ["claude", "-p", prompt, "--output-format", "text", "--model", "claude-opus-4-6"]
        logger.info("Running Claude without session (one-off prompt)")

    logger.info("Prompt character count: %d", len(prompt))
    logger.info("Spawning claude subprocess cwd=%s", project_dir or "(none)")
    start = time.monotonic()

    try:
        proc = await asyncio.create_subprocess_exec(
            *cmd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
            env=env,
            cwd=project_dir,
        )
        stdout, stderr = await asyncio.wait_for(
            proc.communicate(),
            timeout=config.CLAUDE_TIMEOUT_SECONDS,
        )
    except FileNotFoundError:
        logger.error("Claude CLI binary not found - is it installed?")
        raise RuntimeError(
            "Claude CLI is not installed or not in PATH"
        )
    except PermissionError:
        logger.error("Claude CLI binary is not executable")
        raise RuntimeError(
            "Claude CLI lacks execute permissions"
        )
    except OSError as exc:
        logger.error("OS error spawning Claude subprocess: %s", exc)
        raise RuntimeError(
            f"Could not spawn Claude CLI process (OS error: {exc.strerror or str(exc)}). "
            "Contact the bot admin - system resources may be exhausted."
        )
    except asyncio.TimeoutError:
        proc.kill()
        await proc.wait()
        elapsed = time.monotonic() - start
        logger.error("Claude subprocess timed out elapsed=%.1fs", elapsed)
        raise TimeoutError(
            f"Claude did not respond within {config.CLAUDE_TIMEOUT_SECONDS}s"
        )

    elapsed = time.monotonic() - start
    logger.info(
        "Claude subprocess finished exit_code=%d elapsed=%.1fs",
        proc.returncode,
        elapsed,
    )

    # Log stderr if present (even on success - might contain warnings)
    err_msg = stderr.decode("utf-8", errors="replace").strip()
    if err_msg:
        if proc.returncode != 0:
            logger.error(
                "Claude subprocess failed exit_code=%d stderr=%s",
                proc.returncode,
                err_msg[:1000],
            )
            raise RuntimeError(f"Claude CLI exited with code {proc.returncode}")
        else:
            logger.warning(
                "Claude subprocess wrote to stderr (exit_code=0): %s",
                err_msg[:1000]
            )
    elif proc.returncode != 0:
        logger.error("Claude subprocess failed exit_code=%d (no stderr)", proc.returncode)
        raise RuntimeError(f"Claude CLI exited with code {proc.returncode}")

    raw = stdout.decode("utf-8", errors="replace").strip()
    return {"text": raw, "trace": []}
