# Handoff

Capture session progress so the next session can pick up cleanly.

## Instructions

Follow these steps to generate a complete handoff document. The result must enable the next session to continue without clarifying questions.

### Step 1 — Gather Git State

Run these commands to understand what happened this session:

1. `git diff --stat` — see what files changed and how much.
2. `git diff` — review the actual changes (staged and unstaged).
3. `git log --oneline -20` — recent commit history for context.
4. `git ls-files --others --exclude-standard` — check for untracked files.

### Step 2 — Identify Work Status

Categorize all work from this session:

- **Goal** — The original task or objective for this session (1-2 sentences).
- **Completed** — What was finished and committed. Number each item. Reference commit hashes.
- **In Progress** — What was started but not finished. Note the current state and what remains.
- **Blocked** — What could not proceed and why. Include the specific blocker.

### Step 3 — Document Decisions

List key decisions made during this session. Use a table for scannability:

```markdown
| Decision | Why |
|----------|-----|
| Choice made | Rationale and alternatives rejected |
```

Include assumptions made that were not verified.

### Step 4 — Record Dead Ends

Document approaches that were tried and abandoned. For each:

- What was attempted
- Why it failed or was rejected
- What was learned

This prevents the next session from repeating failed approaches. If nothing was tried and abandoned, state that explicitly.

### Step 5 — Capture Current State

Note the current status of:

- Key files and directories — what exists, what doesn't yet
- Tests (passing, failing, which ones)
- Lint/type checking (clean or has errors)
- Build (succeeds or broken)
- Branch and uncommitted changes

### Step 6 — Write Next Steps

List concrete, numbered actions for the next session in execution order. Be specific — name files to create, commands to run, issues to close. Not just priority buckets.

Include a recommended first action.

### Step 7 — Identify Critical Files

List files the next session must pay attention to, with a reason for each. Use a table:

```markdown
| File | Why |
|------|-----|
| `path/to/file` | Reason this file matters for the next session |
```

### Step 8 — Check Issue Tracker (if applicable)

If the project uses GitHub Issues, Jira, or another tracker, summarize the status of relevant issues:

```markdown
| Issue | Title | Status |
|-------|-------|--------|
| #1 | Short title | Open / In Progress / Blocked on X |
```

### Step 9 — Write .claude/HANDOFF.md

Write everything from Steps 2-8 to `.claude/HANDOFF.md` using this structure:

```markdown
# Handoff — {date}

## Goal
...

## What Was Done
1. ...
2. ...

## Key Decisions

| Decision | Why |
|----------|-----|
| ... | ... |

## Dead Ends
...

## Current State
...

## Next Steps
1. ...
2. ...

## Files to Pay Attention To

| File | Why |
|------|-----|
| ... | ... |

## Issue Tracker Status

| Issue | Title | Status |
|-------|-------|--------|
| ... | ... | ... |
```

Omit sections that are empty (e.g., no blocked items, no dead ends). Keep the handoff under 100 lines — be concise, reference file paths instead of duplicating content.

### Step 10 — Confirm

Report what was written and remind the developer that the next session will read `.claude/HANDOFF.md` automatically via the "Read These First" directive in `.claude/CLAUDE.md`.
