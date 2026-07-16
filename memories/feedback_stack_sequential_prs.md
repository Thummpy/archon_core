---
name: Stack sequential PRs to avoid merge conflicts
description: When creating multiple PRs that touch overlapping files, rebase downstream branches before each merge — don't let the user hit conflicts repeatedly
type: feedback
originSessionId: 6c904803-e317-49e1-b85e-6d4ea17640a6
---
When lining up multiple PRs from related issues, always rebase downstream PRs onto main BEFORE telling the user to merge each one. Better yet, stack the branches (each branches from the previous) so merges are conflict-free.

**Why:** User hit the same .env.example/README.md conflict three times in a row across PRs #54, #55, #56 because all branched from the same main point. Each merge caused the next PR to conflict. The orchestrator should have handled this silently instead of spamming chat with repeated rebase attempts.

**How to apply:** Before saying "ready to merge," check if the next PR in the sequence will conflict. If yes, rebase it first. When creating multiple issues/PRs in sequence, explicitly note the dependency chain and handle rebases between merges automatically.
