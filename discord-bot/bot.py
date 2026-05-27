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
    os.makedirs(os.path.dirname(HEALTH_SENTINEL), exist_ok=True)
    pathlib.Path(HEALTH_SENTINEL).touch()


def _load_slash_commands() -> None:
    commands_dir = pathlib.Path(config.COMMANDS_DIR)
    if not commands_dir.is_dir():
        logger.info("No commands directory at %s, skipping slash command load", commands_dir)
        return

    for cmd_file in sorted(commands_dir.glob("*.md")):
        cmd_name = cmd_file.stem
        logger.info("Registering slash command /%s from %s", cmd_name, cmd_file)

        content = cmd_file.read_text(encoding="utf-8")

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


async def _handle_slash_command(
    ctx: discord.ApplicationContext,
    cmd_name: str,
    cmd_content: str,
    args: str,
) -> None:
    await ctx.defer()
    prompt = f"/{cmd_name} {args}\n\n---\n\n{cmd_content}".strip()

    channel = ctx.channel
    channel_name = getattr(channel, "parent", channel).name if hasattr(channel, "parent") else channel.name
    project_dir = _project_dir_for_channel(channel_name)

    try:
        response = await claude_runner.run_claude(prompt, project_dir=project_dir)
        for chunk in _split_response(response):
            await ctx.followup.send(chunk)
    except (TimeoutError, RuntimeError) as exc:
        logger.error("Slash command /%s failed error=%s", cmd_name, exc)
        await ctx.followup.send(f"Command `/{cmd_name}` failed: {exc}")


def _split_response(text: str, limit: int = 2000) -> list[str]:
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
    logger.info("Bot connected as %s servers=%d", bot.user, len(bot.guilds))
    _touch_health_sentinel()
    print(f"✓ Bot connected to Discord as {bot.user}", file=sys.stderr)


@bot.event
async def on_message(message: discord.Message) -> None:
    if message.author == bot.user:
        return
    if message.author.bot:
        return

    channel = message.channel

    if isinstance(channel, discord.Thread):
        parent_name = channel.parent.name
    else:
        parent_name = channel.name

    if parent_name not in config.CHANNEL_MAP:
        return

    thread = await _ensure_thread(message, channel)
    await _handle_thread_message(message, thread, parent_name)


async def _ensure_thread(
    message: discord.Message,
    channel: discord.abc.Messageable,
) -> discord.Thread:
    if isinstance(channel, discord.Thread):
        return channel

    thread = await message.create_thread(
        name=f"Claude — {message.content[:50]}",
        auto_archive_duration=1440,
    )
    return thread


async def _handle_thread_message(
    message: discord.Message,
    thread: discord.Thread,
    channel_name: str,
) -> None:
    lock = _get_lock(thread.id)
    async with lock:
        messages = await thread_manager.load_context(thread.id)
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
            except (TimeoutError, RuntimeError) as exc:
                logger.error("Claude failed thread_id=%d error=%s", thread.id, exc)
                await thread.send(f"Sorry, I encountered an error: {exc}")
                return

        messages.append({"role": "assistant", "content": response})
        await thread_manager.save_context(thread.id, messages)

        for chunk in _split_response(response):
            await thread.send(chunk)

        _touch_health_sentinel()


def main() -> None:
    _load_slash_commands()
    logger.info("Starting bot with server_id=%d", config.DISCORD_SERVER_ID)
    bot.run(config.DISCORD_BOT_TOKEN)


if __name__ == "__main__":
    main()
