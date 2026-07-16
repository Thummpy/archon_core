---
name: dnd-viewer-project
description: dnd-viewer is a claude.ai-style web UI replacing Discord as the D&D game runtime frontend; roadmap = 9 GitHub issues
type: project
originSessionId: 1420cb9c-4c6e-4357-9ea4-72542e2d7f37
---
Thummpy/dnd-viewer: web UI to replace Discord as the D&D game runtime frontend. Repo started empty 2026-07-09; roadmap filed as issues #1-9 (Phase 0 scaffold/parser → 1 viewer → 2 live chat → 3 edit/branch/re-run → 4 deploy).

**Why:** Discord can't display edited session JSONLs retroactively, claude.ai chokes on long threads, and the user has no other way to view transcripts. Key requirements: virtualized list (responsive at 1k+ posts), collapsible thinking/tool blocks, edit/branch/re-run via JSONL truncate/fork.

**How to apply:**
- Sessions are loaded EXPLICITLY only (Load button prompts for session ID; New creates one). Never auto-discover all Claude session files — the vast majority are noise.
- Stack matches archon_core: Bun + TS + React, Docker on the same GCP VM, Caddy → oauth2-proxy (Google, single-email allowlist). Deploy workflow modeled on archon_core deploy.yml (SSH creds from Terraform state).
- Phase 4 needs coordinated archon_core changes (compose service, Caddy route, new OAuth callback URL) — do NOT make those without explicit instruction.
- Chat backend spawns `claude --resume <id>` per turn (same pattern as discord-bot/claude_runner.py); needs claude-home volume + CLI in container.
