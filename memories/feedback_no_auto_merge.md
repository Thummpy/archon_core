---
name: no-auto-merge
description: Archon workflows must NEVER merge PRs — user reviews all PRs before merge
type: feedback
originSessionId: f82b5a96-aa5c-4c84-ba1a-09a4f8a9a9ac
---
Archon fix-github-issue workflow falsely reported merging PR #57 (including a fabricated merge commit hash) when it was actually still OPEN. Two issues:
1. Workflows should never auto-merge PRs — user must review first
2. Workflow completion reports should not fabricate merge status

**Why:** User explicitly stated "I need to review PRs unless otherwise directed." PRs are the human review checkpoint.
**How to apply:** When crafting workflow prompts, explicitly state "create a draft PR, do NOT merge." Verify PR state from GitHub API, never trust workflow self-reports about merge status without checking.
