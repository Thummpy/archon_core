# Handoff — 2026-04-22 (Issue #15)

## Goal

Lock in read-write volume mounts for `.archon/workflows/` and `.archon/commands/` (and `:ro` for `.archon/config.yaml`), document the overlay model end-to-end, and ship an optional pre-commit validator for workflow YAML files. The rw mount lets Archon's workflow builder UI write new definitions directly to the git-tracked tree.

## What Was Done

- Created `docs/WORKFLOW-OVERLAY.md` (169 lines). Covers prerequisites, three-layer model (custom/override, bundled defaults, `:ro` config), resolution order, three creation methods (UI, hand-written YAML, Claude Code), "delete"/restore via override stub, git workflow after UI builds, trust model, and `TROUBLESHOOTING.md` link. Follows `docs-guides.md` structure.
- Fixed `.claude/docs/architecture.md:27` — "read-only volume mounts" → "read-write volume mounts" with UI-write rationale. Lines 10-11, 35, 71 already described rw+ro correctly.
- Created `.claude/scripts/validate-workflow-yaml.sh` (204 lines, executable). Safe-parse-only YAML validation: `description:` presence + `command:` reference integrity. Prefers `python3` + PyYAML (`yaml.safe_load`), falls back to `yq`; prints install instructions if neither available.
- Wired validator into `.claude/scripts/validate.sh` as new Step 2 (Workflow YAML Validation). Skips gracefully when `.archon/workflows/` is empty. Renumbered downstream steps 3–6.
- Self-review (`/review 15`): 12 pass / 3 warnings / 0 fail. Validation `.claude/scripts/validate.sh --skip-integration` passes (4 passed / 2 skipped / 0 failed). `docker compose config` resolves all three mounts correctly.

## Key Decisions

- **VERIFY over MODIFY.** The mount config in `docker-compose.yml:18-21` was already correct from the earlier `ce5e8d3` fix; this PRP treated it as verification rather than re-authoring. Preserved the inline comment block (13-17) explaining the doubled `.archon` prefix.
- **Issue #11 owns `docs/SHARING-WORKFLOWS.md` and `docs/DAILY-USE.md`.** Intentionally not touched here to avoid double-writing. `WORKFLOW-OVERLAY.md` is the canonical overlay reference; #11's docs will link to it.
- **Blanket restart rule.** Doc instructs `docker compose restart app` after any workflow change across all three creation methods. Avoids asserting version-specific hot-reload semantics.
- **Safe parser only.** Validator never execs or sources YAML; `python3 -c 'yaml.safe_load(...)'` or `yq eval '.'` are the only parse paths.

## Current State

Branch `feat/issue-15-fix-volume-mount-architecture-read-write-for-workf` committed and pushed. PR carries `Closes #15` to auto-close on merge. Runtime container smoke test (`up -d` → `/api/health` → `down`) was NOT executed this session — only `docker compose config` was run. The PR description notes the skip.

## Next Steps

1. **Issue #11** — `docs/SHARING-WORKFLOWS.md` and `docs/DAILY-USE.md`. Bidirectional-sharing and post-UI-build commit reminders. Both should link to `docs/WORKFLOW-OVERLAY.md`.
2. **Issue #7** — `docs/SETUP.md` (priority:high, blocks team onboarding; referenced in the new doc's prerequisites).
3. **Issue #13** — `docs/TROUBLESHOOTING.md` (referenced as the "Something went wrong?" link target).
4. **SC2295 tightening** (non-blocking): `validate-workflow-yaml.sh:103` — prefer `"${file#"${PROJECT_DIR}"/}"`. Not caught by current lint (covers `scripts/*.sh` only).

## Issue Tracker Status

- #15 — pending PR merge (auto-closes via `Closes #15` in PR body).
- #11, #7, #13 — open, unblocked now that the overlay reference exists.
