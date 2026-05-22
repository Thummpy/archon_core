# Handoff — Issue #43: Fix CLI Unavailability, Health Workflow Count, and Built-in Audit

## Goal
Three concrete gaps prevented this Archon wrapper repo from being usable in practice: (1) all `archon` CLI workflow commands in docs exit 127 (binary not in container PATH), (2) `scripts/health.sh` reported "Workflows loaded: unknown" by calling the same broken CLI, and (3) `atyeti-pev.yaml` was referenced in multiple files but does not exist.

## What Was Done

- **`scripts/health.sh`**: Replaced `check_workflows` — removed `archon workflow list` pipeline, added `curl GET /api/workflows` + `grep -o '"name":' | wc -l` to count workflows. Added `WORKFLOWS_ENDPOINT` named constant. Now outputs `Workflows loaded: 20`.
- **`docs/DAILY-USE.md`**: Rewrote five sections — merged "Running a workflow from the CLI/Web UI" into one Web UI-only "Running a workflow" section (step-by-step, "what you should see"); replaced broken `archon workflow status/resume/approve/reject` with Web UI + `docker compose logs`; replaced `archon isolation list/cleanup` with `docker compose exec app ls /.archon/workspaces/`; replaced `archon doctor` with `./scripts/health.sh` as primary + `bun` invocation as advanced option; streamlined "Workflow not found" troubleshooting.
- **`docs/SHARING-WORKFLOWS.md`**: Fixed stale line-116 "what you should see" (was: `archon workflow list`; now: Web UI at `/workflows`).
- **`docs/TROUBLESHOOTING.md`**: Removed redundant CLI sentence from "Workflow not appearing" step 4.
- **`docs/SETUP.md`**: Removed `atyeti-pev.yaml` reference; updated "what you should see" to explain empty `.archon/workflows/` is expected.
- **`docs/WORKFLOW-OVERLAY.md`**: Added "Built-in workflow audit" section — `archon-piv-loop` is PIV superset (no custom PEV workflow needed), `archon-workflow-builder` complements the DLC.
- **`.claude/CLAUDE.md`**: Removed `atyeti-pev.yaml` from project structure diagram and naming convention example.
- **`.claude/docs/smoke-tests.md`**: Appended Test 31 — CLI invocation via full path and `bun` (PARTIAL: diagnostics work, execution fails on missing Claude Code SDK native binary).

## Key Decisions

- **Web UI for execution, `bun` for diagnostics**: The CLI limitation is not a PATH fix — the Claude Code SDK native binary is absent from the container image. This is permanent upstream design (no fork planned). Diagnostic commands (`doctor`, `workflow list`) work via `bun /app/packages/cli/src/cli.ts` and are documented as an advanced option only.
- **`/api/workflows` for health count**: No `jq` dependency; `grep -o '"name":' | wc -l` is sufficient.
- **No custom `atyeti-pev.yaml`**: `archon-piv-loop` is a functional superset. `.archon/workflows/` remains empty (`.gitkeep` only) until team-specific workflows are authored.

## Current State

PR open on `feat/issue-43-fix-resolve-cli-unavailability-broke`, targeting main. Issue #43 closes on merge. All validation passes (`shellcheck`, `validate.sh`). Container running on 0.3.12; `./scripts/health.sh` outputs `Workflows loaded: 20`.

## Issue Tracker
- Issue #43: closes on PR merge
