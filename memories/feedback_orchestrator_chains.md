---
name: orchestrator-runs-chains
description: Multi-issue sequential work is orchestrated BY the main thread, never via in-workflow human review gates
type: feedback
originSessionId: 1420cb9c-4c6e-4357-9ea4-72542e2d7f37
---
For sequential multi-issue work, the orchestrator thread runs archon-fix-github-issue per issue, reviews each resulting PR itself, and only stops if a critical issue needs human intervention. NEVER put a human review gate inside a workflow (e.g. archon-workflow-chain's pause-for-review mode).

**Why:** The user has no in-Archon means to review work mid-workflow and no in-workflow channel to approve/deny — a paused workflow is a dead end. (Related: feedback_no_approval_prompts — permission prompts don't propagate either.)

**How to apply:** Loop per issue: (1) invoke archon-fix-github-issue for issue N, branching from the prior PR's branch (first from main); (2) when results return, orchestrator reviews the PR diff itself; (3) if no critical problems, invoke the next issue stacked on that branch; (4) stop and report only on critical findings. PRs are never merged by me or workflows — user merges at their leisure.
