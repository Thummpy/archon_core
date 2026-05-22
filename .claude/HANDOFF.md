# Handoff — Issue #46: Fix verify-workflow-sharing.sh for 0.3.12

## Goal

Fix three bugs in `scripts/verify-workflow-sharing.sh` that caused the script to always report `PARTIAL` on a healthy 0.3.12 system:
1. CLI probe permanently exits 127 (upstream packaging decision) — classification never reached PASS
2. Stale 0.3.6 error message in `probe_api()` claiming YAML is not scanned at startup (false in 0.3.12)
3. Stale "Record in Test 30" instruction (already recorded for both 0.3.6 and 0.3.12)

## What Was Done

Single file changed: `scripts/verify-workflow-sharing.sh`

| Change | Detail |
|--------|--------|
| Removed `probe_cli()` | 46-line function deleted; `archon` binary absent by upstream design |
| Removed `CLI_RESULT` global | No orphaned references remain |
| Rewrote classification | 2-axis (API + mount); returns PASS when both pass |
| Fixed `probe_api()` error message | Version-neutral: `"Workflow not discovered — check container logs: docker compose logs app"` |
| Updated `usage()` | Lists 2 checks (was 3); no CLI mention |
| Renumbered `probe_mount()` | "Check 3" → "Check 2" |
| Replaced Test 30 instruction | Now: `"Append this result to .claude/docs/smoke-tests.md if testing a new Archon image tag."` |

## Key Decisions

- **CLI probe removed, not patched**: Test 31 in smoke-tests.md confirms `archon` binary is absent by upstream design. Any gate on CLI would permanently block PASS — removal is the only correct fix.
- **Classification reduced to 2-axis**: Mount probe preserved because it validates Docker Compose volume config independently of Archon's application-level discovery.

## Current State

All changes committed and pushed. PR open on `feat/issue-46-fix-ops-update-verify-workflow-sharing-for-0-3-12`. Issue #46 closes on merge. Validation: 4/4 passed, 2 skipped.

## Next Steps

No open issues remain after #46 merges. Check `gh issue list --state open` for new backlog items.
