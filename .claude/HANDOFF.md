# Handoff — Issue #30: Verify git-pull workflow sharing

## Goal

Definitively test whether a hand-placed YAML file in `.archon/workflows/`
(simulating `git pull` delivery) appears in Archon's Web UI or CLI after
`docker compose restart app`. Correct all documentation based on findings.

## What Was Done

1. Created `scripts/verify-workflow-sharing.sh` — probes three channels:
   API (`/api/workflows`), CLI (`archon workflow list`), and container
   filesystem bind-mount. Includes health gating, EXIT trap cleanup, and
   structured PASS/FAIL/UNAVAILABLE summary per channel.

2. Ran the script against live Archon 0.3.6. Findings:
   - **API: FAIL** — `/api/workflows` returns `{"workflows":[]}`. No startup
     scan of `/.archon/.archon/workflows/`; UI reads SQLite exclusively.
   - **CLI: UNAVAILABLE** — `archon` binary not in container PATH, exit 127.
     All `docker compose exec app archon ...` commands fail the same way.
   - **Bind-mount: PASS** — YAML file confirmed in container filesystem.

3. Recorded Test 30 in `.claude/docs/smoke-tests.md` with verbatim output
   and criterion-by-criterion analysis (append-only; Test 24 untouched).

4. Corrected five documentation files:
   - `docs/WORKFLOW-OVERLAY.md` — four "What you should see" sections updated
   - `docs/SHARING-WORKFLOWS.md` — "issue #30/under investigation" refs replaced;
     verification step changed to `docker compose exec app ls`
   - `docs/DAILY-USE.md` — caveat added for unavailable `archon workflow list`;
     "Workflow not found" troubleshooting item corrected
   - `docs/TROUBLESHOOTING.md` — item 4 in workflow-not-appearing section updated

## Key Decisions

- CLI classified UNAVAILABLE (not FAIL) — binary doesn't exist in PATH, which
  is stronger than "command fails to list workflow".
- "Workflow not found" troubleshooting in DAILY-USE.md was out of original PRP
  scope but gave users broken advice (exit-127 error); fixed in review pass.
- Follow-up issue #38 created for remaining `archon` CLI sections in DAILY-USE.md
  (`archon workflow run/status/resume/doctor/isolation`) — need separate
  investigation of whether an alternative invocation exists.

## Next Steps

- **Issue #38** — investigate `archon` CLI invocation in container and correct
  remaining CLI sections in `docs/DAILY-USE.md`
- **Issue #25** — OAuth token lifetime and refresh behavior (Test 25 pending)
