# Handoff — 2026-04-22

## Goal

Create the foundational `docker-compose.yml` for the archon-setup project (Issue #1).

## What Was Done

- Created `docker-compose.yml` — pinned `ghcr.io/coleam00/archon:0.3.6`, host-path volume at `${HOME}/archon-data`, read-write mounts for `.archon/workflows` and `.archon/commands`, read-only config mount, localhost-only port, bridge network, healthcheck, DNS, IPv6 sysctl.
- Created `.env.example` with `CLAUDE_CODE_OAUTH_TOKEN`, `PORT`, `RCLONE_REMOTE` documented.
- Created `.archon/` skeleton — `workflows/.gitkeep`, `commands/.gitkeep`, `config.yaml` (minimal, commented).
- Updated `.gitignore` — added `backups/` under a project-specific section.
- Updated `.claude/scripts/validate.sh` — Type Check block now handles missing `.env` on fresh clones by copying `.env.example` temporarily; adds EXIT trap for safe cleanup; renamed var to `temp_env_created`.
- Updated `.claude/commands/plan-feature.md` — added `git push -u origin` step after branch creation (per feedback memory).

## Key Decisions

- **Read-write mounts** for workflows/commands (not read-only as original Issue #1 AC stated) — per PLANNING.md architecture decision and Issue #15 correction.
- **Double `.archon` nesting** in container paths (`/.archon/.archon/workflows`) — Archon resolves scan paths relative to its home dir `/.archon`. Verified in upstream `packages/paths/src/archon-paths.ts`. Comment added in compose file.
- **`${HOME}` not `~`** in host-path volume — `~` does not expand in Docker Compose.
- **`ARCHON_DOCKER=true`** required — upstream entrypoint uses it to set archon home to `/.archon`.

## Current State

Issue #1 committed and PR created. Branch deleted after merge.

## Next Steps (priority order)

1. **Issue #15** — Close manually; rw volume mount was implemented as part of Issue #1.
2. **Issue #2** — `health.sh` script (priority:high)
3. **Issue #3** — `setup-oauth.sh` script (priority:high)
4. **Issue #5** — `atyeti-pev.yaml` PEV workflow (priority:high)
5. **Issue #7** — `docs/SETUP.md` first-time guide (priority:high, blocks team onboarding)
6. **Issue #8** — `sync-up.sh` / `sync-down.sh` (priority:high)

## Issue Tracker Status

- Issue #1: closed via PR. Issue #15: still open — close it with a note that rw mounts were implemented in the Issue #1 PR.
