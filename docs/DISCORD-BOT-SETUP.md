# Discord Bot Setup

Connect Claude Code to your Discord server so that messages in designated channels
automatically spawn Claude Code CLI sessions and respond in threads.

## What you need before starting

- A working archon-setup installation (see [SETUP.md](SETUP.md))
- A Discord account with **admin permissions** on the target server
- The Discord server ID (default: `1509185927505907715`)
- About 15 minutes

## Step 1: Create a Discord Application

Go to the [Discord Developer Portal](https://discord.com/developers/applications) and
click **New Application**. Give it a name (e.g. "Archon Bot").

**What you should see:** A new application page with an Application ID.

## Step 2: Create a Bot User

In your application, click **Bot** in the left sidebar, then **Add Bot**.

Under **Privileged Gateway Intents**, enable:

- **Message Content Intent** — required for the bot to read message text
- **Server Members Intent** — required for member lookup

**What you should see:** A Bot section with a token (hidden by default) and two intents
toggled on.

## Step 3: Copy the Bot Token

Click **Reset Token** (or **Copy** if visible) to get the bot token.

> **Keep this token secret.** Anyone with it can control your bot. Never commit it to
> version control.

Add the token to your `.env` file:

```bash
DISCORD_BOT_TOKEN=your-token-here
```

If deploying via Terraform/GCP, the token is stored in Secret Manager as
`archon-chris-discord-bot-token` (project: `dev-services-497603`) and injected
automatically at VM startup.

**What you should see:** The token appears in your `.env` file when you run
`grep DISCORD_BOT_TOKEN .env`.

## Step 4: Invite the Bot to Your Server

In the Developer Portal, go to **OAuth2 > URL Generator**.

Select these scopes:

- `bot`
- `applications.commands`

Select these bot permissions:

- Send Messages
- Create Public Threads
- Send Messages in Threads
- Read Message History
- Use Slash Commands

Copy the generated URL and open it in your browser. Select your server and authorize.

**What you should see:** The bot appears in your server's member list (offline until
started).

## Step 5: Start the Bot

From the archon-setup directory:

```bash
docker compose up -d discord-bot
```

Check that it started successfully:

```bash
docker compose logs discord-bot
```

**What you should see:**

```
[discord-bot] Token validated, starting bot...
✓ Bot connected to Discord as YourBotName#1234
```

## Step 6: Verify It Works

In the `#dnd-context` channel of your Discord server, type a message. The bot should:

1. Create a new thread from your message
2. Respond with Claude Code's output inside the thread

Continue the conversation by replying in the thread. Each thread maintains its own
conversation context for up to 100 messages, after which it archives automatically.

## Using Slash Commands

Slash commands are automatically loaded from `.archon/commands/` at bot startup. For
example, if you have a `plan.md` command file, you can use `/plan` in Discord.

```
/plan Build a REST API for user management
```

The bot reads the command file content, appends your arguments, and sends it all to
Claude Code.

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `DISCORD_BOT_TOKEN` | (required) | Bot authentication token |
| `DISCORD_SERVER_ID` | `1509185927505907715` | Target Discord server |
| `CLAUDE_CODE_OAUTH_TOKEN` | (required) | Anthropic OAuth token for Claude Code |

Channel-to-project mapping is defined in `discord-bot/config.py`:

```python
CHANNEL_MAP = {
    "dnd-context": "Thummpy/dnd-context",
}
```

To add more channels, update the map and restart the bot:

```bash
docker compose restart discord-bot
```

## Something went wrong?

**Bot is offline in Discord:**

```bash
docker compose ps discord-bot
docker compose logs discord-bot --tail 50
```

Check that `DISCORD_BOT_TOKEN` is set in `.env` and the token is valid.

**Bot does not respond to messages:**

- Verify the bot has Message Content Intent enabled in the Developer Portal
- Verify the message is in a mapped channel (e.g. `#dnd-context`)
- Check logs: `docker compose logs discord-bot --tail 20`

**"ERROR: DISCORD_BOT_TOKEN environment variable is not set":**

Add the token to `.env`:

```bash
echo "DISCORD_BOT_TOKEN=your-token" >> .env
docker compose restart discord-bot
```

**Claude Code times out:**

The default timeout is 120 seconds. If Claude consistently takes longer, check that
the Claude Code CLI is installed correctly inside the container:

```bash
docker compose exec discord-bot claude --version
```

For other issues, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md).
