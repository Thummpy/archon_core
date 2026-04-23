# PRP: Verify Archon 0.3.6 workflow/commands scan paths match docker-compose.yml bind mounts

## Objective

Verify — against a running `ghcr.io/coleam00/archon:0.3.6` container — that Archon actually reads the paths `docker-compose.yml:18-19` bind-mounts for workflows (`/.archon/.archon/workflows`) and commands (`/.archon/.archon/commands`). The doubled-`.archon` target was inferred from upstream source code and documented in `docs/WORKFLOW-OVERLAY.md`, but never observed on the live image. Capture the AC's four probes verbatim, record findings to a new durable runbook at `.claude/docs/smoke-tests.md` (designed to be re-executed on every future tag bump), and either (a) strengthen `docs/WORKFLOW-OVERLAY.md` with a dated verification reference on PASS, or (b) open a follow-up issue and annotate `docs/WORKFLOW-OVERLAY.md` with a correction note on FAIL. This issue itself does NOT modify `docker-compose.yml` under any outcome.

## Ticket Reference

GitHub Issue #23 — "Verify Archon 0.3.6 workflow/commands scan paths match docker-compose.yml bind mounts" — blocks #7, precedes #24/#25.

## MUST READ

- `file: docker-compose.yml` — `why: lines 18-19 are the bind-mount targets under test; the inline comment at lines 14-17 cites upstream source references that this issue's evidence supersedes`
- `doc: docs/WORKFLOW-OVERLAY.md` — `why: current prose claiming the doubled-.archon target is correct; lines ~20 table and line 38 callout; output of this PRP either strengthens or corrects this doc`
- `file: scripts/health.sh` — `why: used as the health gate; note that it also shells archon workflow list inside the container (line 103) — if that succeeds it is a secondary signal that scan paths resolve`
- `file: .claude/PLANNING.md` — `why: overlay model and host-path volume design decisions that this test validates empirically`
- `doc: .claude/rules/docs-guides.md` — `why: prerequisites section and "Something went wrong?" footer conventions apply if correction prose lands in docs/WORKFLOW-OVERLAY.md`
- `url: https://github.com/coleam00/archon/releases/tag/0.3.6` — `why: release notes for the pinned tag; scan for any mention of scan paths or home dir changes before assuming the paths are stable`

## CRITICAL

- **`.env` must contain a non-empty `CLAUDE_CODE_OAUTH_TOKEN`** or the container's workflow-running code paths fail silently even though `docker compose up` and `/api/health` return OK. Verify as Task 1 before proceeding; agent cannot run `scripts/setup-oauth.sh` because it requires interactive browser auth.
- **Issue #23 MUST NOT modify `docker-compose.yml`** even on FAIL. Any fix to the mount target is deferred to a follow-up issue opened in Task 12. This is a hard AC constraint.
- **Directory presence alone is not proof of scanning.** Docker auto-creates bind-mount target paths when the container starts. If `ls -la` shows `/.archon/.archon/workflows` exists, that does not prove Archon reads it. The authoritative signal is the `find` probe in Task 7 — it reveals whether there are OTHER `workflows`/`commands` directories inside the image at paths Archon might scan instead.
- **Multi-location output is possible and may be correct.** The `find` probe may surface both the bind-mount target AND a bundled-defaults directory (e.g., `/app/.../workflows`). `docs/WORKFLOW-OVERLAY.md` already describes an overlay model where bundled defaults coexist with host overrides. Treat a multi-location result as PASS if the bind-mount target is one of the returned paths; treat it as FAIL only if the bind-mount target is absent.
- **Health gate is necessary but not sufficient.** `scripts/health.sh` can return 0 while Archon is reading the wrong directory. Do not use the health gate as the sole verification signal.
- **HANDOFF.md from the #7 session labeled mount paths "Pass (pre-verified via `bd5ad77` source references)."** That was code-reference inference, not runtime observation. This issue supersedes that claim with live evidence.
- **Redaction.** The AC's `printenv` probe is narrowly scoped (`grep -iE "archon|home|pwd"`) and will not match `CLAUDE_CODE_OAUTH_TOKEN`. Verify visually in captured output that no token-prefixed variable leaked before committing.

## Security Considerations

- The captured output committed to `.claude/docs/smoke-tests.md` must contain zero secrets. The `printenv | grep` filter is designed to exclude the OAuth token; visually confirm before writing to file. If any token-shaped value surfaces in any probe, redact to `<REDACTED>` before recording.
- The durable doc is git-tracked and will sync via `rclone` per the project's cross-machine workflow. Treat it as public-within-the-team.
- Container is bound to `127.0.0.1:${PORT:-3000}` per `docker-compose.yml:9`. The smoke test does not expose new network surface.

## External Constraints

- Pinned image: `ghcr.io/coleam00/archon:0.3.6`. All findings are tagged to this version; subsequent tag bumps re-run this runbook.
- Docker daemon must be running (user confirmed Docker Desktop is up). If the Docker socket is unreachable at Task 2, abort and ask the user.
- `docs/WORKFLOW-OVERLAY.md:40` already states "This document describes behavior at image tag `ghcr.io/coleam00/archon:0.3.6`." The "verified on" line added in Task 11 (PASS branch) should live adjacent to this statement.
- `.claude/docs/smoke-tests.md` is a new file with a structure designed for appending one `## Verification log — Archon <tag> (verified <date>)` section per tag bump. Never overwrite prior entries.

## Data Models

No data model changes. Artifacts produced:

- `.claude/docs/smoke-tests.md` — new durable runbook (created)
- `docs/WORKFLOW-OVERLAY.md` — one-line addition on PASS, correction-note block on FAIL

## Implementation Tasks

Legend: `[agent]` = I execute, `[user-validate]` = I execute, user confirms interpretation, `[user-perform]` = user must do before I can proceed.

1. **VERIFY** `[user-validate]` — Confirm `.env` at repo root has a non-empty `CLAUDE_CODE_OAUTH_TOKEN`. Agent runs `grep -cE '^CLAUDE_CODE_OAUTH_TOKEN=.+' .env` and reports count. If 0, ABORT and ask user to run `scripts/setup-oauth.sh`.

2. **VERIFY** `[agent]` — Run `docker info >/dev/null 2>&1 && echo "daemon OK"`. If this fails, ABORT and ask user to start Docker Desktop.

3. **ADD** `[agent]` — Bring the container up: `docker compose up -d`. Poll `scripts/health.sh` every 5s up to 12 iterations (60s). On timeout, capture `docker compose logs app --tail 50` and ABORT with the log.

4. **FIND** `[agent]` — Capture runtime identity: `docker compose exec -T app id` and `docker compose exec -T app sh -c 'echo HOME=$HOME; echo PWD=$(pwd)'`. Retain verbatim output.

5. **FIND** `[agent]` — Probe mount targets: `docker compose exec -T app ls -la /.archon/.archon/workflows /.archon/.archon/commands`. Retain verbatim, including owner/group/perms. If either path does not exist, flag as ANOMALY (should never happen — Docker creates mount points even if host dir is empty).

6. **FIND** `[agent]` — Probe environment: `docker compose exec -T app sh -c 'printenv | grep -iE "archon|home|pwd" | sort'`. Retain verbatim. Confirm token did not leak into the match set before committing.

7. **FIND** `[agent]` — AC's authoritative probe: `docker compose exec -T app sh -c 'find / -type d \( -name workflows -o -name commands \) 2>/dev/null | grep -i archon'`. Retain verbatim multi-line output.

8. **FIND** `[agent]` — Supplementary probe: `docker compose exec -T app sh -c 'find / -maxdepth 6 -type d -name ".archon" 2>/dev/null'` to catch alternate `.archon` roots. Retain verbatim.

9. **VERIFY** `[user-validate]` — Classify outcome based on Task 7 output:
   - **PASS** — `/.archon/.archon/workflows` AND `/.archon/.archon/commands` appear in the find output (possibly alongside bundled-default directories inside the image).
   - **FAIL** — Neither bind-mount target appears in the find output, or Archon's directories are clearly rooted elsewhere (e.g., `/app/workflows` with no `.archon` variant).
   - **PARTIAL** — One target present, one absent, or targets present but permissions prevent write. Escalate for user judgment.
   
   Agent presents the captured output and proposes a classification; user confirms or overrides before proceeding.

10. **CREATE** `[agent]` — Write `.claude/docs/smoke-tests.md` with this structure:
    - `# Smoke tests — per-tag verification runbook` heading + one-paragraph purpose
    - `## How to use` section: explains that every new image tag bumps in `docker-compose.yml` require appending a new `## Verification log — Archon <tag>` section. Never overwrite prior entries.
    - `## Verification log — Archon 0.3.6 (verified 2026-04-23)` section containing:
      - `### Test 23 — workflow/commands scan paths` — what's tested (1 paragraph), commands executed (code block), verbatim captured output (code block), classification + rationale
      - `### Test 24 — UI write-back to host bind-mount` — status: pending (issue #24)
      - `### Test 25 — OAuth token lifetime` — status: pending (issue #25)

11. **MODIFY** `[agent]` — **PASS branch only.** In `docs/WORKFLOW-OVERLAY.md`, locate the existing tag-pin disclosure (line ~40: "This document describes behavior at image tag `ghcr.io/coleam00/archon:0.3.6`"). Append a one-line sibling: `> Verified against this image on 2026-04-23 — see [`.claude/docs/smoke-tests.md`](../.claude/docs/smoke-tests.md#test-23--workflowcommands-scan-paths).` Preserve all surrounding prose.

12. **MODIFY** `[agent]` — **FAIL branch only.**
    - (a) Draft the body of a new GitHub issue titled `Fix docker-compose.yml bind-mount target path — mismatch discovered by #23`. Body includes: observed bind-mount target, actual scan path per captured evidence, proposed correction, link to `.claude/docs/smoke-tests.md#test-23--workflowcommands-scan-paths`.
    - (b) `[user-validate]` Show the drafted issue body to user. On approval, run `gh issue create --title ... --body ... --label infrastructure,priority:high` to open it.
    - (c) Add a correction-note admonition block to `docs/WORKFLOW-OVERLAY.md` at the top of the document directing readers to the new follow-up issue.
    - (d) Reference the new issue number in the smoke-tests doc's Test 23 entry.

13. **VERIFY** `[agent]` — Run `.claude/scripts/validate.sh`. Expect Pass on Lint / Type Check / Build; Skip acceptable on Unit/Integration. No new failures allowed.

14. **REMOVE** `[agent]` — `docker compose down`. Confirm `~/archon-data/` and `.archon/` host paths are intact (`ls ~/archon-data/archon.db` and `ls .archon/workflows/`).

## Validation Commands

```bash
# Preflight
grep -cE '^CLAUDE_CODE_OAUTH_TOKEN=.+' .env
docker info >/dev/null 2>&1 && echo "daemon OK"

# Bring up + gate
docker compose up -d
scripts/health.sh

# Four AC probes (inside container)
docker compose exec -T app ls -la /.archon/.archon/workflows /.archon/.archon/commands
docker compose exec -T app sh -c 'printenv | grep -iE "archon|home|pwd" | sort'
docker compose exec -T app sh -c 'find / -type d \( -name workflows -o -name commands \) 2>/dev/null | grep -i archon'
docker compose exec -T app sh -c 'find / -maxdepth 6 -type d -name ".archon" 2>/dev/null'

# Project validation
.claude/scripts/validate.sh

# Teardown
docker compose down
```

## Acceptance Criteria

- [ ] `docker compose up -d` starts Archon and `scripts/health.sh` returns exit 0
- [ ] `ls -la` confirms both bind-mount target directories exist and are writable by Archon's runtime user
- [ ] `printenv` probe output recorded verbatim with no secret leakage
- [ ] `find` probe output recorded verbatim (single or multi-line)
- [ ] Runtime scan paths confirmed to include the bind-mount targets — OR — follow-up issue opened AND correction note added to `docs/WORKFLOW-OVERLAY.md`
- [ ] `.claude/docs/smoke-tests.md` created with Verification Log section for 0.3.6 (Test 23 complete; Tests 24/25 marked pending)
- [ ] On PASS: `docs/WORKFLOW-OVERLAY.md` has a dated "Verified on" line; on FAIL: it has a top-of-doc correction-note admonition
- [ ] `.claude/scripts/validate.sh` passes; no new lint or type errors
- [ ] `docker compose down` succeeds; `~/archon-data/archon.db` and `.archon/workflows/` intact
- [ ] GitHub Issue #23 closed (via PR merge) at the end of `/commit-close`

## Confidence Score

**Score:** 9/10

**Justification:** The AC's four probes are deterministic and mechanical; the runbook format is straightforward. The one reason this is not 10 is interpretive: Task 7's `find` output against the 0.3.6 image filesystem cannot be fully predicted without running it. A multi-location result (bind-mount target plus an additional bundled-defaults path) is plausible and semantically different from a clean single-path match — that disambiguation is delegated to Task 9's user-validate step by design, not by omission. The branch between PASS (Task 11, one-line doc addition) and FAIL (Task 12, follow-up issue + correction note) is symmetrical and each path is fully specified. Container-up/down, health gating, `.env` precheck, and Docker-daemon precheck are all covered. The PRP also explicitly keeps `docker-compose.yml` untouched per the AC's hard constraint.
