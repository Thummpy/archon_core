---
name: golden-record-protocol
description: For irreplaceable state files (session JSONLs, campaign persistent files), show plan and get explicit go before ANY destructive edit — even when invoking a skill whose spec looks autonomous
type: feedback
originSessionId: f1424295-0752-49fe-8d4d-d8c716e878da
---
Golden-record files (live session JSONLs at ~/.claude/projects/, campaign episode JSONs, transcript files, any single-source-of-truth artifact the user cannot regenerate) are NEVER to be edited without an explicit show-plan-and-confirm cycle. This applies even when:
- The user invokes a skill (/compacter, /rewind, etc.) that describes execution steps
- You have a backup ready
- The edit "looks reversible"
- The skill spec appears to authorize autonomous execution

**Why:** the user has said "critical cardinal sin" about silently truncating the live session record during /compacter. A backup does not authorize the operation — it only protects against tool failure. Silent optimization ("those lines are structurally invisible on resume anyway, so dropping them is equivalent") is the classic malfunction — the spec's rules exist for reasons beyond what's visible to Claude at read time (in that case: preserving the append-only recovery invariant of native compaction).

Also do not reinterpret spec steps to be "cleaner" or "more efficient" than written. If a spec says "dead history, untouched," it means UNTOUCHED — not "structurally-equivalent-drop-in." If the spec seems over-cautious, ask before deviating.

**How to apply:**
- Before ANY edit to a golden-record file, output: (a) exact division/edit points with line numbers, (b) proposed content deltas, (c) byte-level before/after estimate, (d) which lines are touched vs preserved. Then STOP and wait for a "go."
- The skill spec authorizes the METHOD. The user authorizes the MOMENT. Both are required.
- For /compacter specifically: show the resolved division user post opening text, show the summary text for review, show the exact-lines-touched list, then wait.
- "Restore from backup" is always faster than "explain to the user why I destroyed their record." Default to over-communication on destructive irreversible ops.
