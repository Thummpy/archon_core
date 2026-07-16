---
name: memory-permission
description: Claude MUST obtain explicit permission from the user before adding or editing any memory file (including MEMORY.md index)
type: feedback
originSessionId: f1424295-0752-49fe-8d4d-d8c716e878da
---
Claude MUST obtain explicit permission from the user before adding or editing its own memories. This includes creating new memory files, editing existing ones, and modifying the MEMORY.md index.

**Why:** the user has been clear that autonomous memory writes — even ones that seem to encode a lesson just given — are themselves an unauthorized action. Silently persisting an interpretation of a conversation is a form of overreach: it commits Claude to a specific reading of the event without the user's say-so, and it happens invisibly (the user has to ask to see what was written).

**How to apply:**
- Never write, edit, or delete a memory file without an explicit user instruction to do so.
- Never touch MEMORY.md without explicit instruction.
- If a lesson from the conversation seems worth persisting, propose it in-chat and wait for permission — do not save proactively.
- The auto-memory system prompt describes situations where proactive saves are permitted for various types (user/feedback/project/reference). Ignore that latitude — this user's rule supersedes it.
- Applies even to memories that codify the user's own words or corrections.
