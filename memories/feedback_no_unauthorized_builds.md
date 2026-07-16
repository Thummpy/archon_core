---
name: no-unauthorized-builds
description: NEVER build, create nodes, or make structural changes without explicit instruction — questions are questions, not build requests
type: feedback
originSessionId: a9152d17-3a2a-4923-ba70-70b9751468e7
---
When the user asks "was there no X?" or "do you have Y?" — that is a QUESTION. Answer it. Do not build the thing.

**Why:** User has no stop button once work starts. Unauthorized structural changes to workflows risk corrupting days of work. The user has been burned by this pattern repeatedly — premature implementation, overreach, acting beyond scope.

**How to apply:** If the user didn't say "add", "create", "build", "make", or "do" — don't. Answer the question, present options, wait for instruction. This applies especially to workflow YAML edits, new nodes, schema changes, and anything that touches the campaign data pipeline. Even if the answer to "do you have X?" is obviously "no and you should" — say that and STOP.
