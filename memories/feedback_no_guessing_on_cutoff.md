---
name: no-guessing-on-cutoff
description: When a user message looks cut off or ambiguous, ask — never guess intent and act
type: feedback
originSessionId: 7c6c62af-9152-48e4-abd0-bd920717e14c
---
If a user message appears truncated, fragmentary, or ambiguous, DO NOT infer what they meant and act on the guess. Stop and ask what they intended.

**Why:** User sent "BTW, 'rewind'" (message cut off mid-thought); I guessed it was defining a shorthand and ran off writing memory files. The actual intent was different — a tip about search scope. Guessing wasted a turn and required correction.

**How to apply:** Cut-off messages, lone fragments, or messages ending mid-sentence get a clarifying question, not action. This complements no-premature-implementation and no-unauthorized-builds: ambiguity = ask first.
