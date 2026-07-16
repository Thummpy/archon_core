---
name: context-management-architecture
description: Planned architecture for session context management — strip-session pre-resume, Bash for ephemeral reads (styles/DM files), Read for persistent loads (profiles), file-driven combat state
type: project
originSessionId: eb7e6b00-6456-4bc8-bde3-7bf8a43aef1b
---
Session context management architecture for dnd-context game runtime (discord-bot + Claude Code --resume).

## Core principle: Bash vs Read tool split

| Tool | Use for | Why |
|------|---------|-----|
| **Bash (cat)** | Anything re-read each turn: styles, dm_event, dm_scene, combat state | Strip cleans old reads, prevents accumulation |
| **Read** | Things loaded once and kept: character profiles, party assets, atlas files | Persists through strip, no re-reading needed |

DM files (dm_event, dm_scene) stay on Bash — no migration needed. They're re-read each turn and should be cleaned.

## Strip-session runs pre-resume (bot-side)

Bot calls strip_session.py with the session_id BEFORE `claude --resume`, not as a Claude instruction. This means Claude loads already-clean context each message. Injection point: bot.py `_handle_thread_message()`, after `load_context(thread.id)` returns session_id, before `run_claude()`.

**Why:** Tool results persist in session context. Without pre-strip, Bash results accumulate across --resume boundaries. Running strip before resume gives zero-lag clean context.

**How to apply:** Modify bot.py to call strip_session.py(session_id) between load_context and run_claude. Strip_session.py is in dnd-context repo at `.claude/scripts/strip_session.py`, takes session UUID as arg.

## Style files — loaded via Bash, stripped each cycle

Three style files in `rules/`: user_style_social.md (2k, default), user_style_combat.md (1.5k), user_style_adult.md (12k). CLAUDE.md instructs Claude to `cat` the appropriate style before crafting each response. Bash results are stripped by strip_session, so only one style is ever in context.

**How to apply:** CLAUDE.md Scene Modes section should instruct Claude to determine scene mode and `cat rules/user_style_<mode>.md` before responding. Social is default. Only one style per response.

## Combat state — file-driven, not session-driven

Combat state lives in a temp file on disk, not in session context. Architecture:

- `roll-init` deletes all prior combat temp files, creates fresh one with: init-ordered table (name, HP/AC, etc.), NPC profile copies
- Combat skill reads the temp file each invocation, writes back updated state + appends to log
- Temp file format is dense pseudocode notation (not a program), e.g.:
  ```
  Round 1:
  Rue: ran 30' toward giant3, distance=10'; crossbow@giant3: hit(24),piercing(23)+poison(3) = giant3.hp(45)
  Giant3: spell(fear): Condition(fear)[Bit,Rue,Nax]
  ```
- State section updated in-place each round; log section is append-only
- Log exists for error rollback and mid-combat comprehension
- File persists until next `roll-init` — no strip interaction needed

**Why:** Combat results are critical during combat but dead weight after. File-driven approach means session context only has the most recent Bash read of the temp file (stripped next cycle). The file is the single source of truth. roll-init handles lifecycle (clear old, create new).

## Thinking blocks

strip_session.py preserves all thinking blocks (updated 2026-06-24). No longer strips/filters based on OCEAN/thesis content.
