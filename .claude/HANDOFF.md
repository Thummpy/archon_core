# Handoff — Issue #40: Bump Archon to 0.3.12 and Fix Bind Mount Paths

## Goal
Upgrade pinned Archon image from 0.3.6 to 0.3.12 and update all bind mount paths, docs, and scripts to match the unified path model introduced in upstream PR #1315.

## What Was Done
- `docker-compose.yml`: image tag bumped to 0.3.12; workflow/command mount targets changed from `/.archon/.archon/workflows` and `/.archon/.archon/commands` to `/.archon/workflows` and `/.archon/commands`; inline comment rewritten
- `docs/WORKFLOW-OVERLAY.md`: table, code block, and all path/caveat references updated; "Why the doubled `.archon`?" blockquote removed; version tag updated
- `docs/DAILY-USE.md`, `docs/SHARING-WORKFLOWS.md`, `docs/TROUBLESHOOTING.md`, `docs/UPGRADING.md`, `README.md`: all path references and version-specific CLI caveats updated to version-agnostic language
- `scripts/verify-workflow-sharing.sh`: container path and version string updated
- README.md substantially rewritten (scope included in issue)

## Key Decisions
- CLI-not-in-PATH is a permanent upstream design choice (confirmed via Dockerfile analysis), not version-specific. All docs use version-agnostic language.
- Docs retain "pending re-verification" language for workflow discovery behavior — follow-up needed. See below.

## Live Verification Findings (2026-05-20, 0.3.12)
- Container starts cleanly; `./scripts/health.sh` passes
- Bind mounts confirmed working at `/.archon/workflows/` and `/.archon/commands/`
- `archon workflow list` exits 127 (by design)
- **YAML discovery**: `verify-sharing-test.yaml` placed in `.archon/workflows/` (no SQLite record), container restarted — workflow appeared in `GET /api/workflows` response. PR #1315 unified discovery is operational.
- API returns 20 workflow names on 0.3.12 (docs/DAILY-USE.md table lists 10 from 0.3.6)
- Findings posted verbatim to issue #40 comment

## Current State
PR open, targeting main. Container running on 0.3.12. Docs have "pending re-verification" language — intentionally deferred.

## Next Steps
1. Follow-up issue: update WORKFLOW-OVERLAY.md / SHARING-WORKFLOWS.md caveats to reflect confirmed YAML discovery; record 0.3.12 results in `.claude/docs/smoke-tests.md`
2. Follow-up issue: update DAILY-USE.md built-in workflow table (20 workflows, not 10; list changed significantly)
3. Issue #38 (open) — investigate `archon` CLI invocation alternatives in container

## Issue Tracker
- Issue #40: closes on PR merge
