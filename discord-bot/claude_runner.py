import asyncio
import logging
import os
import time

import config

logger = logging.getLogger("discord-bot.claude")


async def run_claude(prompt: str, project_dir: str | None = None) -> dict:
    """Run Claude CLI and return structured result with text.

    Returns:
        dict with keys:
            text: str — the final assistant text (for sending to Discord)
            trace: list[dict] — always empty for now; traces readable from session JSONL files
    """
    env = os.environ.copy()
    env["CLAUDE_CODE_OAUTH_TOKEN"] = config.CLAUDE_CODE_OAUTH_TOKEN

    cmd = ["claude", "-p", prompt, "--output-format", "text", "--model", "claude-opus-4-6"]

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

    if proc.returncode != 0:
        err_msg = stderr.decode("utf-8", errors="replace").strip()
        logger.error(
            "Claude subprocess failed exit_code=%d stderr=%s",
            proc.returncode,
            err_msg[:1000],
        )
        raise RuntimeError(f"Claude CLI exited with code {proc.returncode}")

    raw = stdout.decode("utf-8", errors="replace").strip()
    return {"text": raw, "trace": []}
