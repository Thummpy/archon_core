---
name: context-overflow-subagents
description: Never step through huge transcripts/files by reading chunks into main context — delegate spans to subagents that return compact findings
type: feedback
originSessionId: 0a9e7fcf-80f1-4f9f-8ae0-a826a57e1251
---
When processing very large files (game transcripts, multi-MB JSONL sessions) chunk-by-chunk, NEVER read the chunks into the main conversation context. After ~10-15 chunks the conversation hits "Prompt is too long" and Archon stalls unrecoverably (no auto-compaction rescue in the SDK path).

**Why:** The Rue-ledger study (2026-07-09) stalled twice this way — 850-line chunks read directly via Read/Bash accumulated ~500k+ tokens.

**How to apply:** Persist state to disk first (working file + ledger/findings file + progress markers with line ranges). Then delegate each span to a fresh-context subagent (Agent tool) with a fully self-contained prompt; the subagent reads the span and returns only a compact findings list (<100 lines) that the orchestrator merges into the on-disk ledger. Main context grows by summaries only. On restart, everything needed to resume is on disk.
