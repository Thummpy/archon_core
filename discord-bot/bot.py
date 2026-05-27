import asyncio
import logging
import os
import pathlib
import sys
import time

import discord

import claude_runner
import config
import thread_manager

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(name)s %(levelname)s %(message)s",
    stream=sys.stderr,
)
logger = logging.getLogger("discord-bot")

intents = discord.Intents.default()
intents.message_content = True
intents.guilds = True
intents.messages = True

bot = discord.Bot(intents=intents)

thread_locks: dict[int, asyncio.Lock] = {}

HEALTH_SENTINEL = os.path.join(config.DATA_DIR, "bot_healthy")
AUTO_ARCHIVE_DURATION_MINUTES = 1440  # 24 hours


def _get_lock(thread_id: int) -> asyncio.Lock:
    if thread_id not in thread_locks:
        thread_locks[thread_id] = asyncio.Lock()
    return thread_locks[thread_id]


def _project_dir_for_channel(channel_name: str) -> str | None:
    project = config.CHANNEL_MAP.get(channel_name)
    if not project:
        return None
    return os.path.join(config.DATA_DIR, "projects", project)


def _touch_health_sentinel() -> None:
    try:
        os.makedirs(os.path.dirname(HEALTH_SENTINEL), exist_ok=True)
        pathlib.Path(HEALTH_SENTINEL).touch()
    except OSError as exc:
        logger.error("Failed to update health sentinel path=%s error=%s", HEALTH_SENTINEL, exc)


def _load_slash_commands() -> None:
    commands_dir = pathlib.Path(config.COMMANDS_DIR)
    if not commands_dir.is_dir():
        logger.info("No commands directory path=%s - skipping slash command load", commands_dir)
        return

    loaded_count = 0
    failed_count = 0

    for cmd_file in sorted(commands_dir.glob("*.md")):
        cmd_name = cmd_file.stem

        try:
            content = cmd_file.read_text(encoding="utf-8")
        except OSError as exc:
            logger.error(
                "Failed to read command file file=%s error=%s - skipping",
                cmd_file,
                exc,
            )
            failed_count += 1
            continue
        except UnicodeDecodeError as exc:
            logger.error(
                "Command file is not valid UTF-8 file=%s error=%s - skipping",
                cmd_file,
                exc,
            )
            failed_count += 1
            continue

        logger.info("Registering slash command cmd_name=%s file=%s", cmd_name, cmd_file)

        # Closure captures loop variables via default args to avoid late binding.
        # Without _content=content, all commands would reference the last file.
        async def _cmd_callback(
            ctx: discord.ApplicationContext,
            args: str = "",
            _content: str = content,
            _name: str = cmd_name,
        ) -> None:
            await _handle_slash_command(ctx, _name, _content, args)

        _cmd_callback.__name__ = cmd_name
        bot.command(
            name=cmd_name,
            description=f"Run {cmd_name} workflow",
            guild_ids=[config.DISCORD_SERVER_ID],
        )(
            discord.option("args", description="Arguments", required=False, default="")(
                _cmd_callback
            )
        )
        loaded_count += 1

    logger.info(
        "Slash command loading complete: loaded=%d failed=%d",
        loaded_count,
        failed_count,
    )
    if failed_count > 0:
        logger.warning("Some command files could not be loaded - check logs for details")


async def _handle_slash_command(
    ctx: discord.ApplicationContext,
    cmd_name: str,
    cmd_content: str,
    args: str,
) -> None:
    await ctx.defer()
    prompt = f"/{cmd_name} {args}\n\n---\n\n{cmd_content}".strip()

    channel = ctx.channel
    if isinstance(channel, discord.Thread) and channel.parent:
        channel_name = channel.parent.name
    else:
        channel_name = channel.name
    project_dir = _project_dir_for_channel(channel_name)

    try:
        response = await claude_runner.run_claude(prompt, project_dir=project_dir)
        for chunk in _split_response(response):
            await ctx.followup.send(chunk)
    except TimeoutError as exc:
        logger.error("Slash command timed out cmd=%s error=%s", cmd_name, exc)
        await ctx.followup.send(
            f"⏱️ Command `/{cmd_name}` timed out after {config.CLAUDE_TIMEOUT_SECONDS}s. "
            "Try a simpler request or contact the bot admin."
        )
    except RuntimeError as exc:
        logger.error("Slash command failed cmd=%s error=%s", cmd_name, exc)
        await ctx.followup.send(
            f"❌ Command `/{cmd_name}` failed. The error has been logged. "
            "Please try again or contact the bot admin."
        )


def _split_response(text: str, limit: int = 2000) -> list[str]:
    """Split response into Discord-compatible chunks at newline boundaries.

    Discord's message limit is 2000 characters. Prefer splitting at newlines
    for readability; fall back to hard split if no newline within limit.
    """
    if len(text) <= limit:
        return [text]
    chunks = []
    while text:
        if len(text) <= limit:
            chunks.append(text)
            break
        split_at = text.rfind("\n", 0, limit)
        if split_at == -1:
            split_at = limit
        chunks.append(text[:split_at])
        text = text[split_at:].lstrip("\n")
    return chunks


@bot.event
async def on_ready() -> None:
    logger.info("Bot connected user=%s server_count=%d", bot.user, len(bot.guilds))
    _touch_health_sentinel()


@bot.event
async def on_message(message: discord.Message) -> None:
    if message.author == bot.user:
        return
    if message.author.bot:
        return

    try:
        channel = message.channel

        if isinstance(channel, discord.Thread):
            parent_name = channel.parent.name if channel.parent else None
        else:
            parent_name = channel.name

        if not parent_name or parent_name not in config.CHANNEL_MAP:
            return

        thread = await _ensure_thread(message, channel)
        await _handle_thread_message(message, thread, parent_name)

    except discord.Forbidden as exc:
        logger.error(
            "Permission denied message_id=%d channel=%s error=%s",
            message.id,
            getattr(message.channel, "name", "unknown"),
            exc,
        )
        try:
            await message.reply(
                "❌ I don't have permission to create threads or send messages here. "
                "An admin needs to grant me: `Create Public Threads`, `Send Messages in Threads`"
            )
        except discord.Forbidden:
            logger.error("Cannot reply to user - no permissions at all")

    except discord.HTTPException as exc:
        logger.error(
            "Discord API error message_id=%d status=%s error=%s",
            message.id,
            getattr(exc, "status", "unknown"),
            exc,
        )
        try:
            await message.reply(
                f"⚠️ Discord API error ({getattr(exc, 'status', 'unknown')}). "
                "This might be temporary - please try again."
            )
        except Exception:
            pass

    except OSError as exc:
        logger.error(
            "File I/O error message_id=%d error=%s",
            message.id,
            exc,
        )
        try:
            await message.reply(
                "⚠️ Failed to save conversation state. "
                "Contact the bot admin - storage may be full."
            )
        except Exception:
            pass

    except Exception as exc:
        logger.exception(
            "Unexpected error in on_message message_id=%d channel=%s",
            message.id,
            getattr(message.channel, "name", "unknown"),
        )
        try:
            await message.reply(
                "❌ An unexpected error occurred. The issue has been logged."
            )
        except Exception:
            pass


async def _ensure_thread(
    message: discord.Message,
    channel: discord.abc.Messageable,
) -> discord.Thread:
    if isinstance(channel, discord.Thread):
        return channel

    logger.info(
        "Creating new thread message_id=%d channel=%s",
        message.id,
        channel.name,
    )
    thread = await message.create_thread(
        name=f"Claude — {message.content[:50]}",
        auto_archive_duration=AUTO_ARCHIVE_DURATION_MINUTES,
    )
    logger.info("Created thread thread_id=%d thread_name=%s", thread.id, thread.name)
    return thread


async def _handle_thread_message(
    message: discord.Message,
    thread: discord.Thread,
    channel_name: str,
) -> None:
    lock = _get_lock(thread.id)
    async with lock:
        messages = await thread_manager.load_context(thread.id)
        if messages is None:
            # Error loading history - notify user
            await thread.send(
                "⚠️ I couldn't load our conversation history due to a technical issue. "
                "Continuing with a fresh context."
            )
            messages = []

        messages.append({"role": "user", "content": message.content})

        if thread_manager.should_archive(len(messages)):
            await thread.send(
                f"This thread has reached {config.ARCHIVE_THRESHOLD} messages "
                "and will be archived. Please start a new conversation."
            )
            await thread.edit(archived=True)
            return

        project_dir = _project_dir_for_channel(channel_name)

        context_prompt = "\n\n".join(
            f"{'User' if m['role'] == 'user' else 'Assistant'}: {m['content']}"
            for m in messages
        )

        async with thread.typing():
            try:
                response = await claude_runner.run_claude(
                    context_prompt,
                    project_dir=project_dir,
                )
            except TimeoutError as exc:
                logger.error("Claude timed out thread_id=%d error=%s", thread.id, exc)
                await thread.send(
                    f"⏱️ Claude timed out after {config.CLAUDE_TIMEOUT_SECONDS}s. "
                    "Your message was too complex or the service is overloaded. "
                    "Try again with a shorter message."
                )
                return
            except RuntimeError as exc:
                logger.error("Claude failed thread_id=%d error=%s", thread.id, exc)
                await thread.send(
                    "❌ Claude encountered an error processing your message. "
                    "The error has been logged. Please try rephrasing or contact the bot admin."
                )
                return

        messages.append({"role": "assistant", "content": response})

        # Try to save context
        save_failed = False
        try:
            await thread_manager.save_context(thread.id, messages)
        except (OSError, TypeError) as exc:
            save_failed = True
            logger.error(
                "Failed to save context after successful Claude response thread_id=%d error=%s",
                thread.id,
                exc,
            )

        # Try to send response chunks
        send_failed = False
        try:
            for chunk in _split_response(response):
                await thread.send(chunk)
        except discord.Forbidden as exc:
            send_failed = True
            logger.error(
                "Permission denied sending response thread_id=%d error=%s",
                thread.id,
                exc,
            )
            try:
                await thread.send(
                    "❌ I generated a response but lack permission to send it. "
                    "An admin needs to grant me `Send Messages in Threads`."
                )
            except Exception:
                pass
        except discord.HTTPException as exc:
            send_failed = True
            logger.error(
                "Discord API error sending response thread_id=%d status=%s error=%s",
                thread.id,
                getattr(exc, "status", "unknown"),
                exc,
            )
            try:
                await thread.send(
                    f"⚠️ Failed to send response due to Discord API error "
                    f"({getattr(exc, 'status', 'unknown')}). "
                    "This might be temporary - please try again."
                )
            except Exception:
                pass

        # Notify user about save failure (after attempting send)
        if save_failed and not send_failed:
            try:
                await thread.send(
                    "⚠️ **Warning**: I responded but couldn't save our conversation history. "
                    "Storage might be full. Your next message will start a fresh conversation."
                )
            except Exception:
                logger.error("Could not notify user about save failure thread_id=%d", thread.id)

        _touch_health_sentinel()


def main() -> None:
    # Validate claude CLI is available before starting bot
    import shutil
    if not shutil.which("claude"):
        logger.error("Claude CLI not found in PATH - bot cannot function")
        print("ERROR: Claude CLI is not installed.", file=sys.stderr)
        print("  Install with: curl -fsSL https://storage.googleapis.com/anthropic-release/claude/latest/install.sh | sh", file=sys.stderr)
        sys.exit(1)

    logger.info("Claude CLI found at: %s", shutil.which("claude"))

    _load_slash_commands()
    logger.info("Starting bot server_id=%d", config.DISCORD_SERVER_ID)
    bot.run(config.DISCORD_BOT_TOKEN)


if __name__ == "__main__":
    main()
