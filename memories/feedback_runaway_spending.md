---
name: no-runaway-research
description: STOP chasing rabbit holes — use the exact files the user names, grep directly, don't scan wrong files or spawn agents
type: feedback
originSessionId: 210abcf4-72e1-41fe-9973-9ed74ba48fdb
---
When the user specifies a file path, USE THAT FILE. Do not scan other files "just in case" or follow tangential leads. If the user says "the session is X.jsonl" then X.jsonl is the only session file. Period.

Do NOT read huge narrative chunks into context — grep for what you need, read the specific lines, done.

Do NOT write massive reply novels explaining derivation methodology. The user doesn't want meta-commentary about profiles ("E:70 was confirmed in thinking blocks" / "thesis captures the psychology"). Just write the profile.

**Why:** This behavior burns $100+/day in tokens and fills context with useless material. The user is on overages. Every wasted tool call and every paragraph of unwanted explanation costs real money.

**How to apply:**
1. User names a file → use that file, not a different one
2. grep for the thing → read the matching lines → done
3. Write the actual content, not evaluations OF the content
4. Keep replies SHORT — the edit is the deliverable, not the explanation
5. Benna ≠ Berta (different characters at different locations)
