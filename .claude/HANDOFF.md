# Handoff — Issue #27 complete; Issue #23 ready to resume

## Goal
Fix the container restart-loop caused by `:ro` on the `config.yaml` bind mount blocking the entrypoint chown.

## What Was Done
- Removed `:ro` from `docker-compose.yml` config.yaml mount — the Archon 0.3.6 entrypoint runs `chown -Rh appuser:appuser /.archon` on every start and exits fatally against any read-only target inside `/.archon`
- Added `PORT: "${PORT:-3000}"` to the `environment:` block — without this, PORT wasn't reaching the container so Archon defaulted to port 3090 while the healthcheck checked 3000 (mismatch)
- Deleted a stale 16-byte text placeholder at `~/archon-data/archon.db` left from a prior test; Archon created a valid 4KB SQLite database on first clean boot
- Moved `open-webui` from port 3000 → 3051 (it had `--restart always` holding port 3000; Archon now owns 3000)
- Updated all docs that claimed config was `:ro`: `PLANNING.md`, `architecture.md`, `WORKFLOW-OVERLAY.md`, `.archon/config.yaml` header

## Key Decisions
- `:ro` on anything inside `/.archon` is permanently forbidden — the entrypoint walks the whole tree on every boot
- Trust model is now uniform: workflows, commands, and config are all `rw`; `git diff` is the audit trail for all three

## Current State
- Archon running healthy on port 3000; `docker compose up -d` with no args works on a clean machine
- `scripts/health.sh` returns exit 0; real SQLite DB at `~/archon-data/archon.db`
- Issue #27 PR open; auto-closes on merge

## Next Steps
1. Merge PR #27
2. `git checkout main && git pull`
3. `git checkout feat/issue-23-verify-archon-0-3-6-workflow-commands-scan-paths-m && git rebase main`
4. Resume #23 from Task 1 using `.claude/prps/23-verify-archon-scan-paths.md` — health gate now passes

## Issue Tracker
- #27 — CLOSED by this PR
- #23 — PAUSED, unblocked, ready to resume (PRP committed to this branch)
- #24, #25 — unblocked (both depend on healthy container)
