# Handoff — Issue #45: Fix stale SQLite discovery claim in docs

## Goal

Three documentation files carried a 0.3.6-era claim that a workflow builder save stalling at ~89% leaves the workflow invisible in the Web UI until the token is fixed and the save retried. In 0.3.12, YAML files are discovered at startup — a `docker compose restart app` surfaces the workflow immediately without a SQLite record.

## What Was Done

Updated five occurrences across three docs:

| File | Location | Change |
|------|----------|--------|
| `docs/DAILY-USE.md` | Line 242 + fix guidance | Stale claim removed; restart-discovery language added; fix guidance opens with restart-first workaround |
| `docs/SHARING-WORKFLOWS.md` | Line 92 blockquote | Stale "not in Web UI" claim → restart-discovery language |
| `docs/SHARING-WORKFLOWS.md` | Line 136 subsection | Same replacement |
| `docs/TROUBLESHOOTING.md` | Cause paragraph | Stale "does not appear" claim → restart-discovery language |
| `docs/TROUBLESHOOTING.md` | Fix section opening | Added restart-first step (review WARN: Cause said restart helps, Fix didn't echo it) |

`docs/WORKFLOW-OVERLAY.md` intentionally untouched — already correct, served as reference language.

## Key Decisions

- **Restart-first ordering**: Fix guidance leads with `docker compose restart app` (immediate relief) before `setup-oauth.sh + retry` (permanent fix). Mirrors the DAILY-USE.md pattern.
- **TROUBLESHOOTING.md Fix section**: PRP scoped to Cause only, but review WARN found the Fix section asymmetric with the updated Cause. One-line addition front-loads the restart — consistent with all other updated locations. Issue #46 is unrelated (script bug), so fix was included here.
- **WORKFLOW-OVERLAY.md out of scope**: PRP CRITICAL — lines 56-58 intentionally hold both old caveat and 0.3.12 correction side-by-side as a layered explanation.

## Current State

All changes committed and pushed. PR open on `feat/issue-45-fix-stale-sqlite-discovery-claim`. Issue #45 closes on merge. Validation passes (4/4, 2 skipped).

## Next Steps

- **Issue #46** (open): Update `scripts/verify-workflow-sharing.sh` for 0.3.12. Three bugs: classification always yields PARTIAL (API=PASS + CLI=UNAVAILABLE), stale error message in `probe_api()`, stale "Record in Test 30" instruction. Recommendation: remove CLI probe, rewrite classification as API+mount only.
