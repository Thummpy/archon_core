# Compact: $ARGUMENTS

Compress context for a long-running session while preserving critical state.

## Instructions

The following must survive compaction: **$ARGUMENTS**

If `$ARGUMENTS` is empty, preserve everything currently in progress.

### Step 1 — Capture Current State

Write a `.claude/HANDOFF.md` with the current session state (follow the same process as `/handoff`):

- Completed work
- In-progress work and current state
- Blocked items
- Key decisions made
- Recommended next steps

### Step 2 — Identify Preservation Targets

From `$ARGUMENTS`, identify what context must be retained after compaction:

- Specific files or modules being worked on
- Active GitHub Issue context (run `gh issue list --state open` if needed)
- Error states or debugging context that would be expensive to reconstruct

### Step 3 — Summarize Droppable Context

List what can be safely dropped from the conversation context:

- Exploration results already captured in `.claude/HANDOFF.md`
- File contents that can be re-read from disk
- Resolved discussions or decisions already documented
- Failed approaches already recorded in Dead Ends

### Step 4 — Report

Summarize:

1. What was preserved in `.claude/HANDOFF.md`
2. What the preservation targets are (from `$ARGUMENTS`)
3. What can be dropped
4. Suggest the developer start a new session if context is severely degraded, reading `.claude/HANDOFF.md` to resume
