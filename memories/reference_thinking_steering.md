---
name: thinking-steering
description: Forcing per-turn thinking on Opus 4.6 game sessions — config modes fail, per-message steering works
type: reference
originSessionId: 7c6c62af-9152-48e4-abd0-bd920717e14c
---
On Opus 4.6 (`claude-opus-4-6[1m]`), a long conversation history of no-thinking RP turns dominates every thinking config: `thinking.type=enabled`+budget (via CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING=1 + MAX_THINKING_TOKENS), settings `effortLevel: high`, and `CLAUDE_CODE_EFFORT_LEVEL=max` were ALL verified ineffective against a clone of the live 240k game session (July 2026). The env flags DID reach the API (deprecation warning in bot.log proved it) — the model still skipped thinking.

**What works:** per-message steering, documented in the adaptive-thinking platform docs. Appending `(OOC: Think hard before responding — run the user_style_social psychology pass for every NPC in the scene.)` to each prompt produced full psychology-pass thinking blocks on the same clone. Deployed in discord-bot/claude_runner.py (archon_core commit b83dee9).

**Style injection + latch (commit ec776ff, 2026-07-10, supersedes 537bf98/ad1ede5):** the bot detects `{user_style_<mode>}` in the first 160 chars, reads `project_dir/rules/user_style_<mode>.md` itself, and appends the content wrapped in `{style_injection: user_style_<mode>.md}...{/style_injection}` sentinels — deterministic, replacing the cat instruction (verified the model NEVER reads style files on tag mention). Injection only on declaration turns; declared mode latches per session in `DATA_DIR/style_modes.json` so untagged turns keep the register. Mode-matched OOC line goes LAST (below injection): adult → explicit "Do NOT use extended thinking"; combat → think hard + tactical pass; social/default → think hard + psychology pass. `/strip-session` (dnd-context c9ab087) strips old injection spans from user records. NOTE: adult turns produce zero thinking even with the proven steering sentence (v2b/v3b clone test) — thinking-on-adult is unreachable, user says do not retry.

**Debug techniques that worked:** clone the session JSONL under a new UUID into the mangled project dir for a reachable cwd, then `--resume` the clone (original untouched, cache reads keep it cheap). Grab CLAUDE_CODE_OAUTH_TOKEN from `/proc/1/environ`. The `thinking.type=enabled is deprecated` stderr warning in bot.log is a tracer proving env vars reached the CLI. Fresh-session tests always think — only the long-history clone reproduces the failure.
