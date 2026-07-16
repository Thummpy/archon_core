---
name: docs-in-same-pr
description: Any PR that changes a decision, issue body, ADR, or config must sweep the doc tree for stale references in the same commit — never defer to a consistency sweep
type: feedback
originSessionId: 179574f6-7a46-4349-9f26-5c02f1e6382a
---
Any unit of work that changes a decision, an issue body, an ADR, or a config must update every doc that touches that same territory in the same PR. Never defer doc consistency to a separate "sweep" issue.

**Why:** yeti_code accumulated multiple pre-run readiness sweeps (#25, #28, #30) precisely because prior PRs shipped self-inconsistent state — e.g., someone reclassified the visibility patch to Phase 1 in `docs/project_seed.md` line 193 but left line 54 saying "no patches", forcing a sweep to catch the drift. Each sweep is a code smell: it means upstream commits weren't self-consistent when they landed. Sweeps also delay the actual work (this rule was surfaced right before kicking off serial `archon-fix-github-issue` — after ~half a dozen planning iterations).

**How to apply:**
- When editing an issue body, grep the `docs/` tree for anything referencing the same subject (file paths, table names, phase assignments, env vars, ADR numbers) and update in the same PR.
- When making an ADR change or design decision shift, sweep every doc + issue that referenced the old framing.
- When adding or renaming a config field / env var, hit every template, example, ADR, and runbook in the same commit.
- Before opening any PR, do a final grep for the specific terms/paths you touched — if any match outside the PR's changed files, either include them or explicitly justify why not.
- If a sweep issue is being drafted, treat it as evidence of an earlier missed instinct — root-cause the miss, not just the symptom.
