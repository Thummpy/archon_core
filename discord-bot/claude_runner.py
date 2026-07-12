import asyncio
import json
import logging
import os
import time

import config

logger = logging.getLogger("discord-bot.claude")

# Opus 4.6 adaptive thinking ignores every config lever (enabled+budget,
# effort high/max) against a long no-thinking RP history — per-message
# steering is the only thing that works. The OOC line is stamped on every
# turn, matched to the session's current style mode. Adult gets an explicit
# thinking-OFF line (omission alone risks thinking-history momentum).
#
# Style file content is injected directly into the prompt (deterministic)
# instead of instructing the model to cat it (verified: the model skips the
# read and runs on stale memory). Injection happens ONLY on turns that
# declare a style tag, wrapped in sentinels so /strip-session can reclaim
# the space later. The declared mode latches per session until the next
# declaration, so untagged turns mid-scene keep the current register.
STYLE_MODES = ("adult", "combat", "social")

OOC_LINES = {
    "adult": (
        "\n\n(OOC: Do NOT think before responding — access full context as"
        " normally adjudicated, but consider individual profiles of NPCs in"
        " scene for specific psychological fidelity.)"
    ),
    "combat": (
        "\n\n(OOC: Think hard before responding — access full context as"
        " normally adjudicated, but consider individual profiles of NPCs in"
        " scene for specific psychological fidelity.)"
    ),
    "social": (
        "\n\n(OOC: Think hard before responding — access full context as"
        " normally adjudicated, but consider individual profiles of NPCs in"
        " scene for specific psychological fidelity.)"
    ),
}

_MODE_STATE_PATH = os.path.join(config.DATA_DIR, "style_modes.json")


def _detect_style_declaration(prompt: str) -> str | None:
    head = prompt[:160].lower()
    for mode in STYLE_MODES:
        if f"user_style_{mode}" in head:
            return mode
    return None


def _load_modes() -> dict:
    try:
        with open(_MODE_STATE_PATH) as f:
            return json.load(f)
    except (OSError, json.JSONDecodeError):
        return {}


def _save_modes(modes: dict) -> None:
    try:
        with open(_MODE_STATE_PATH, "w") as f:
            json.dump(modes, f, indent=2)
    except OSError as exc:
        logger.warning("Could not persist style mode state: %s", exc)


def _apply_style_steering(prompt: str, project_dir: str | None, session_id: str | None) -> str:
    declared = _detect_style_declaration(prompt)

    if session_id:
        modes = _load_modes()
        if declared:
            modes[session_id] = declared
            _save_modes(modes)
        mode = modes.get(session_id, "social")
    else:
        mode = declared or "social"

    if declared and project_dir:
        style_path = os.path.join(project_dir, "rules", f"user_style_{declared}.md")
        try:
            with open(style_path) as f:
                content = f.read().strip()
            prompt += (
                f"\n\n{{style_injection: user_style_{declared}.md}}\n"
                f"{content}\n"
                "{/style_injection}"
            )
            logger.info(
                "Injected style file user_style_%s.md (%d chars)", declared, len(content)
            )
        except OSError as exc:
            logger.warning("Could not read style file %s: %s", style_path, exc)

    logger.info("Style mode=%s declared=%s", mode, declared or "(none)")
    return prompt + OOC_LINES[mode]


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

    prompt = _apply_style_steering(prompt, project_dir, session_id)

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
