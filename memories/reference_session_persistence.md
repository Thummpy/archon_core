---
name: session-persistence-architecture
description: How session persistence works across Archon (SDK) vs Claude Code CLI — restore works on CLI, not in Archon chat
type: reference
originSessionId: da27e23b-36e8-4760-954c-a67532905a25
---
## Session Persistence

- `.claude/` is now volume-mounted (persistent across container restarts) via `${HOME}/archon-data/claude-home:/home/appuser/.claude`
- Archon keeps workflow/session data in SQLite at `/.archon/archon.db` (also persistent)
- `claude --restore` works at the CLI level (host laptop, Channels) to resume prior sessions
- Archon chat does NOT support `--restore` — it runs via Agent SDK (`/app/node_modules/@anthropic-ai/claude-agent-sdk-*`), not the Claude Code CLI. No `claude` binary on container PATH.
- Memory files bridge the gap between Archon sessions — they persist and are loaded automatically
