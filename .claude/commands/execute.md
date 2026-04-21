# Execute PRP: $ARGUMENTS

Implement a PRP (Product Requirements Prompt) step-by-step with validation.

## Instructions

You are implementing the PRP at: **$ARGUMENTS**

Follow these steps precisely. Do not skip steps or take shortcuts.

### Step 1 — Verify Clean State

Before starting, verify the working tree is clean and you are on the correct branch:

1. `git status` — confirm no uncommitted changes that could conflict.
2. `git branch --show-current` — confirm the correct branch.

If the tree is dirty, ask the developer whether to stash, commit, or proceed.

### Step 2 — Read the PRP

Read the PRP file at `$ARGUMENTS`. Use ULTRATHINK to deeply analyze:

- The objective and acceptance criteria
- Every implementation task and its directive verb
- All MUST READ references — read each one now
- CRITICAL notes and security considerations
- Validation commands you will need to run

### Step 3 — Load Project Context

Read these files:

1. `.claude/CLAUDE.md` — coding standards and conventions you must follow
2. `.claude/PLANNING.md` — architecture and constraints
3. Any `.claude/rules/` files relevant to the directories you will modify

### Step 4 — Study Patterns

Check `.claude/examples/patterns/` and `.claude/examples/reference-implementations/` for approved patterns. Your implementation must conform to these patterns where applicable.

### Step 5 — Break Into Tasks

Extract the numbered implementation tasks from the PRP. Create a todo list to track progress. Each task should be completable and verifiable independently.

### Step 6 — Implement

For each task in order:

1. Mark the task as in-progress.
2. Implement the change. Follow the directive verb exactly:
   - **CREATE** — Write a new file or component.
   - **MODIFY** — Change an existing file. Read it first.
   - **FIND** — Locate code matching a description. Do not guess.
   - **ADD** — Append to an existing structure.
   - **REMOVE** — Delete code or files. Verify nothing depends on it.
   - **PRESERVE** — Explicitly do not change this. Verify it is unchanged.
   - **MIRROR** — Match the pattern of an existing implementation.
   - **VERIFY** — Run a check or test to confirm a condition.
3. After each significant change, run relevant validation (lint, type check, tests).
4. If any validation fails: **stop**. Diagnose the failure. Fix it. Re-validate. Do not continue to the next task with broken code.
5. Mark the task as complete.

### Step 7 — Verify Completeness

After all tasks are done:

1. Re-read the PRP from the beginning.
2. Check every acceptance criterion. Confirm each one is satisfied.
3. Check every CRITICAL note. Confirm none were violated.
4. If anything was missed, implement it now.

### Step 8 — Run Full Validation

Run `.claude/scripts/validate.sh` to execute the complete validation suite (lint, type check, unit tests, integration tests, build).

If any validation command from the PRP's Validation Commands section exists, run those too.

Fix any failures before proceeding.

### Step 9 — Update Task Tracking

If new tasks were discovered during implementation, create GitHub Issues for them with `gh issue create`. Do not close the original issue — that happens automatically when you run `/commit-close`.

### Step 10 — Report

Summarize what was implemented:

1. List of tasks completed (with brief description of what changed)
2. Any deviations from the PRP and the reasoning
3. Validation results (all passing, or issues remaining)
4. Any follow-up work identified

Do not commit yet. Proceed to `/review` to self-review the changes against project standards.
