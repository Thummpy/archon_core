---
name: verified-model-ids
description: Tested and verified Claude model ID strings for Archon workflows — pinned versions that avoid 4.7/S4.6 overreach
type: reference
originSessionId: 0c815b7f-e5e6-4f0d-850f-8f34b6c9ede6
---
## Verified Model IDs (tested 2026-05-26 via model-verify workflow)

| Purpose | Model ID string | Confirmed version |
|---------|----------------|-------------------|
| D&D game engine (discord-bot) | `claude-fable-5[1m]` | Fable 5 with extended thinking |
| Planning/review | `claude-opus-4-6[1m]` | Opus 4.6 with extended thinking |
| Planning/review (no thinking) | `claude-opus-4-6` | Opus 4.6 |
| Execution/implementation | `claude-sonnet-4-5-20250929[1m]` | Sonnet 4.5 with extended thinking |
| Execution/implementation (no thinking) | `claude-sonnet-4-5-20250929` | Sonnet 4.5 |
| Cheap classification | `haiku` | Haiku 4.5 (short name OK) |

## DO NOT USE

| Short name | Resolves to | Why |
|------------|------------|-----|
| `sonnet` | claude-sonnet-4-6 | Overreaches like Opus 4.7 |
| `opus` | Ambiguous (may resolve to 4.7) | Opus 4.7 is extremely unreliable |
| `opus[1m]` | Ambiguous | Same risk |

## Notes

- Fable 5 added 2026-07-02 — not yet validated, validation in progress
- Pre-4.6 models use dated IDs: `claude-sonnet-4-5-20250929` (the date is part of the ID)
- 4.6+ models use dateless IDs: `claude-opus-4-6` (pinned snapshot, not an alias)
- `claude-sonnet-4-5` (without date) is an API alias that resolves to the dated version — works but less explicit
- In Archon workflow YAML, `model:` field is passed as-is to Claude SDK — no mapping layer
- Archon config.yaml default is `claude-opus-4-6` (correct for planning-tier default)
- Custom workflows in `~/.archon/workflows/` override bundled defaults by same filename (upgrade-safe)
