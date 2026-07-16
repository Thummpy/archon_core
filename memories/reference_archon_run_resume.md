---
name: archon-failed-run-resume
description: Archon resumes the most recent FAILED run of a workflow instead of starting fresh — new prompt is discarded; cancel stale runs in archon.db first
type: reference
originSessionId: 1420cb9c-4c6e-4357-9ea4-72542e2d7f37
---
When a workflow run ends in status `failed`, a later /invoke-workflow of the SAME workflow for that project does NOT start a new run: Archon resumes the failed run, discards the new prompt entirely (user_message stays the old one), skips prior-"successful" nodes, and re-fails at the same node.

Fix before re-invoking: mark the stale run terminal in SQLite —
`bun -e '...'` against `/.archon/archon.db`, table `remote_agent_workflow_runs`, `UPDATE ... SET status='cancelled' WHERE id='<run_id>'`. Valid statuses observed: completed / failed / cancelled. Run logs live at `/.archon/workspaces/<owner>/<repo>/logs/<run_id>.jsonl`; run records show working_path/worktree per run.

Seen 2026-07-09: failed issue-3 fix-github-issue run hijacked the issue-4 invocation and re-failed at verify-pr-base ("no PR for branch") because its PR had been delivered by a different (plan-to-pr) run.
