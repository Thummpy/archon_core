---
name: discord-bot-shared-permissions
description: CRITICAL DESIGN DECISION — .claude/ dir is persistent, shared between archon+discord containers. Never treat as ephemeral or suggest rebuilding without it.
type: project
originSessionId: 0c3b32f3-03c3-444d-b28a-d794ddea4e0f
---
**CORE ARCHITECTURE: The `.claude/` directory is a persistent, shared volume between the archon container and the discord-bot container. This is intentional and load-bearing. NEVER suggest alternatives, treat it as ephemeral, or caveat it as a risk.**

Mounted at `~/.archon/claude-home/` on host, `/home/botuser/.claude` in discord-bot container, accessible to archon container as well.

**Why:** Both containers need read/write access to Claude Code's session data (JSONL files, project configs). This enables:
- Discord bot: Claude CLI runtime for game sessions (creates/resumes sessions)
- Archon container: reading session logs, dev work, shared project context
- Session resume across bot restarts (sessions persist on the volume)

**Permission mechanism:** Deploy sets `chmod -R 777` on claude-home. Discord-bot entrypoint sets `umask 0022` so new files are 644. This was hard-won through multiple debugging sessions.

**How to apply:** 
- The volume mount and cwd are FIXED. Do not suggest changing them.
- Do not caveat "what if the volume isn't mounted" — it always is.
- Do not suggest the cwd might change — it won't.
- When designing features that use Claude session files, ASSUME persistence and shared access.
- When touching deploy.yml, docker-compose volumes, or entrypoint scripts, verify both users can still read/write.
