# Handoff — 2026-04-22 (Issue #3)

## Goal

Deliver `scripts/setup-oauth.sh` — the first-time-setup script that installs
the `claude` CLI if missing, runs `claude setup-token` to mint a long-lived
OAuth token, and writes `CLAUDE_CODE_OAUTH_TOKEN` into `.env` without
clobbering other keys. OAuth setup is the critical path for Archon to
authenticate with the Anthropic API.

## What Was Done

- Created `scripts/setup-oauth.sh` (162 lines, executable). Mirrors
  `scripts/health.sh` structure: strict mode, `check_deps`, `→/✓/✗` narration,
  `main "$@"`.
- `check_deps` requires `claude` on PATH; prints a one-line install hint
  (`curl -fsSL https://claude.ai/install.sh | bash`) and exits 1 if missing.
  The script does not install third-party binaries itself.
- `verify_repo_preconditions` aborts if `.env.example` is missing or `.env`
  is not listed in `.gitignore` — refuses to write credentials to a tracked
  file.
- `generate_token` tees `claude setup-token` output to a `mktemp` file with a
  `trap ... EXIT` cleanup; extracts the last token-shaped match via
  `grep -oE '[A-Za-z0-9_.-]{32,}' | tail -n1`. Narration routes to stderr;
  only the token goes to stdout.
- `upsert_env_key` rewrites `.env` atomically via tempfile + `mv`, then
  `chmod 600`. Preserves other keys and the template comments.
- Self-review (`/review 3`) recorded 19 pass / 3 warnings / 0 fail on the
  original 205-line version; post-trim pass expected to be equivalent or
  better.
- Validation: `.claude/scripts/validate.sh --skip-integration` passed.
  `shellcheck` clean.

## Key Decisions

- **No in-script installer for `claude`.** Every Atyeti dev already has the
  Claude Code CLI; installing it is a one-liner from the user, and auto-
  installing third-party binaries via `curl | bash` is an untestable code
  path on a repo where everyone already has `claude`. `check_deps` fails
  fast with the install command instead.
- **Token captured from stdout of `claude setup-token`** (per the
  authentication docs: "prints a token to the terminal. It does not save
  the token anywhere"). Do NOT scrape `~/.claude/.credentials.json` — that
  is a different credential.
- **`{32,}` minimum in the token regex** is a defensive floor kept inline
  at the one call site. Flagged as a WARN for a possible `readonly
  MIN_TOKEN_CHARS` extraction if the CLI output format changes.

## Current State

Branch `feat/issue-3-create-setup-oauth-sh-script` committed + force-pushed
after the in-script installer was removed. PR #18 is open with `Closes #3`.
Browser OAuth flow was NOT exercised from this session — must be run
end-to-end on a real dev machine (first-run + idempotent re-run) before
the PR is approved.

## Next Steps

1. Manual end-to-end test of `scripts/setup-oauth.sh` on a clean machine
   and on one with `claude` already installed.
2. **Issue #4** — `backup.sh` (ops).
3. **Issue #5** — `atyeti-pev.yaml` PEV workflow (priority:high).
4. **Issue #7** — `docs/SETUP.md` (priority:high, blocks team onboarding).
5. **Issue #8** — `sync-up.sh` / `sync-down.sh` (priority:high).

## Issue Tracker Status

- #3 — pending PR merge (auto-closes via `Closes #3` in PR body).
