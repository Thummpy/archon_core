---
name: archon-visibility-concern
description: Archon chat has no file browser — user can't see the codebase, review PRs, or verify what changed without asking
type: feedback
originSessionId: da27e23b-36e8-4760-954c-a67532905a25
---
There is no file tree or editor view in Archon's chat interface. The user is blind to the codebase unless you explicitly show them. In VS Code they'd just click the file tree. Here they can't.
**Why:** User said "there's no codebase view here. I can't see its current state, it's hidden god knows where until it's merged. I have no way to review anything." This is a fundamental UX gap, not a workflow preference issue.
**How to apply:** Before asking the user to make decisions about code, SHOW them the relevant state (file listings, diffs, tree output). Don't ask "what do you want to do with PR #48?" when they can't see what's in it. This problem gets worse when Archon moves to the cloud — the worktree won't even be on their local machine.
