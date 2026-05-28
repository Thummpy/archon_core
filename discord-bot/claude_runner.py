import asyncio
import json
import logging
import os
import time

import config

logger = logging.getLogger("discord-bot.claude")


async def run_claude(prompt: str, project_dir: str | None = None) -> dict:
    """Run Claude CLI and return structured result with text, thinking, and tool calls.

    Returns:
        dict with keys:
            text: str — the final assistant text (for sending to Discord)
            trace: list[dict] — ordered list of content blocks:
                {"type": "thinking", "content": str}
                {"type": "text", "content": str}
                {"type": "tool_use", "name": str, "input": dict}
                {"type": "tool_result", "tool_use_id": str, "content": str}
    """
    env = os.environ.copy()
    env["CLAUDE_CODE_OAUTH_TOKEN"] = config.CLAUDE_CODE_OAUTH_TOKEN

    cmd = ["claude", "-p", prompt, "--output-format", "stream-json"]

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
    return _parse_stream_json(raw)


def _parse_stream_json(raw: str) -> dict:
    """Parse stream-json output into structured result."""
    text_parts: list[str] = []
    trace: list[dict] = []
    result_text: str | None = None

    for line in raw.split("\n"):
        line = line.strip()
        if not line:
            continue
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            continue

        event_type = event.get("type")

        if event_type == "assistant":
            for block in event.get("message", {}).get("content", []):
                block_type = block.get("type")
                if block_type == "text":
                    text_parts.append(block["text"])
                    trace.append({"type": "text", "content": block["text"]})
                elif block_type == "thinking":
                    trace.append({"type": "thinking", "content": block.get("thinking", "")})
                elif block_type == "tool_use":
                    trace.append({
                        "type": "tool_use",
                        "name": block.get("name", ""),
                        "tool_use_id": block.get("id", ""),
                        "input": block.get("input", {}),
                    })

        elif event_type == "tool":
            for block in event.get("message", {}).get("content", []):
                if block.get("type") == "tool_result":
                    content = block.get("content", "")
                    if isinstance(content, list):
                        content = "\n".join(
                            b.get("text", str(b)) for b in content
                        )
                    trace.append({
                        "type": "tool_result",
                        "tool_use_id": block.get("tool_use_id", ""),
                        "content": str(content)[:5000],
                    })

        elif event_type == "result":
            result_text = event.get("result", "")

    text = "\n".join(text_parts) if text_parts else (result_text or raw)
    return {"text": text.strip(), "trace": trace}
