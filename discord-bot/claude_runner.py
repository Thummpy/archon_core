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
    env["CLAUDE_CODE_AUTO_COMPACT_WINDOW"] = "900000"

    # Opus 4.6 adaptive thinking skips thinking on RP turns no matter which
    # config is used (enabled+budget, effort high, effort max all verified
    # ineffective against a long no-thinking conversation history). Per-message
    # steering is the documented lever that works, so append it to every turn.
    # Steering is scene-style-aware: a {user_style_*.md} tag at the top of the
    # post selects the register. Adult scenes get NO think-hard instruction —
    # the psychology pass reads as clinical in that register, and without
    # explicit steering the long RP history reliably suppresses thinking.
    # The cat instruction forces a fresh read of the style file every time;
    # verified the model otherwise ignores the tag and runs on stale memory.
    head = prompt[:160].lower()
    if "user_style_adult" in head:
        steer = (
            "\n\n(OOC: cat rules/user_style_adult.md and follow it — do not"
            " rely on memory of it. Do NOT use extended thinking this turn —"
            " no deliberation, respond directly in-register.)"
        )
    elif "user_style_combat" in head:
        steer = (
            "\n\n(OOC: cat rules/user_style_combat.md and follow it — do not"
            " rely on memory of it. Think hard before responding — run the"
            " tactical pass: every NPC fights to win.)"
        )
    else:
        steer = (
            "\n\n(OOC: cat rules/user_style_social.md and follow it — do not"
            " rely on memory of it. Think hard before responding — run the"
            " user_style_social psychology pass for every NPC in the scene.)"
        )
    prompt = prompt + steer

    base_cmd = ["claude", "-p", prompt, "--output-format", "text", "--model", "claude-opus-4-6[1m]"]

    if session_id:
        if is_new_session:
            cmd = ["claude", "--session-id", session_id] + base_cmd[1:]
            logger.info("Creating new Claude session session_id=%s", session_id)
        else:
            cmd = ["claude", "--resume", session_id] + base_cmd[1:]
            logger.info("Resuming Claude session session_id=%s", session_id)
    else:
        cmd = base_cmd
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

    if proc.returncode != 0:
        err_msg = stderr.decode("utf-8", errors="replace").strip()
        if err_msg:
            logger.error(
                "Claude subprocess failed exit_code=%d stderr=%s",
                proc.returncode,
                err_msg[:1000],
            )
        else:
            logger.error("Claude subprocess failed exit_code=%d (no stderr)", proc.returncode)
        raise RuntimeError(f"Claude CLI exited with code {proc.returncode}")

    err_msg = stderr.decode("utf-8", errors="replace").strip()
    if err_msg:
        logger.warning("Claude subprocess wrote to stderr (exit_code=0): %s", err_msg[:1000])

    raw = stdout.decode("utf-8", errors="replace").strip()
    return {"text": raw, "trace": []}
