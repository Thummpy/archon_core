# Smoke tests — per-tag verification runbook

This file records live evidence from running Archon smoke tests against specific image tags. Each verification section is append-only — prior entries are never overwritten. When `docker-compose.yml` is bumped to a new image tag, append a new `## Verification log — Archon <tag>` section and re-run each pending test.

## How to use

1. Bring the container up: `docker compose up -d && scripts/health.sh`
2. Run each test's commands verbatim inside the container via `docker compose exec -T app ...`
3. Record verbatim output and classify each test as PASS / FAIL / PARTIAL
4. On PASS: update the relevant doc with a dated verification reference pointing here
5. On FAIL: open a follow-up GitHub issue and add a correction note to the relevant doc
6. Append the new log section — never edit prior entries

---

## Verification log — Archon 0.3.6 (verified 2026-04-23)

### Test 23 — workflow/commands scan paths

**What is tested:** Confirms that workflow and command files placed in `.archon/workflows/` and `.archon/commands/` in this repo are actually seen by Archon inside the container. The Docker bind mounts use a doubled-`.archon` path (`/.archon/.archon/workflows`) because Archon resolves scan paths relative to its runtime home (`/.archon`), not relative to the repo root.

**Commands executed:**

```bash
# Preflight
grep -cE '^CLAUDE_CODE_OAUTH_TOKEN=.+' .env    # → 1
docker info >/dev/null 2>&1 && echo "daemon OK"  # → daemon OK

# Bring up
docker compose up -d
scripts/health.sh  # → archon-app: running (healthy) | Archon API: OK

# Probe 1: runtime identity
docker compose exec -T app id
docker compose exec -T app sh -c 'echo HOME=$HOME; echo PWD=$(pwd)'

# Probe 2: mount targets exist and are owned by appuser
docker compose exec -T app ls -la /.archon/.archon/workflows /.archon/.archon/commands

# Probe 3: environment (no secret leakage)
docker compose exec -T app sh -c 'printenv | grep -iE "archon|home|pwd" | sort'

# Probe 4: authoritative directory find (key signal)
docker compose exec -T app sh -c 'find / -type d \( -name workflows -o -name commands \) 2>/dev/null | grep -i archon'

# Supplementary: .archon root locations
docker compose exec -T app sh -c 'find / -maxdepth 6 -type d -name ".archon" 2>/dev/null'
```

**Verbatim output:**

```
# Probe 1: runtime identity
uid=0(root) gid=0(root) groups=0(root)
HOME=/root
PWD=/app

# Probe 2: mount targets
/.archon/.archon/commands:
total 0
drwxr-xr-x 3 appuser appuser  96 Apr 22 12:04 .
drwxr-xr-x 4 appuser appuser 128 Apr 23 13:21 ..
-rw-r--r-- 1 appuser appuser   0 Apr 22 12:04 .gitkeep

/.archon/.archon/workflows:
total 0
drwxr-xr-x 3 appuser appuser  96 Apr 22 12:04 .
drwxr-xr-x 4 appuser appuser 128 Apr 23 13:21 ..
-rw-r--r-- 1 appuser appuser   0 Apr 22 12:04 .gitkeep

# Probe 3: printenv (token not present)
ARCHON_DOCKER=true
HOME=/root
PWD=/app

# Probe 4: authoritative find
/app/.archon/workflows
/app/.archon/commands
/.archon/.archon/workflows
/.archon/.archon/commands

# Supplementary: .archon roots
/app/.archon
/.archon
/.archon/.archon

# Archon startup logs (paths_configured + app_defaults_verified)
{"module":"archon-paths","home":"/.archon","workspaces":"/.archon/workspaces","worktrees":"/.archon/worktrees","config":"/.archon/config.yaml","msg":"paths_configured"}
{"module":"archon-paths","commands":"/app/.archon/commands/defaults","workflows":"/app/.archon/workflows/defaults","msg":"app_defaults_verified"}
```

**Classification: PASS**

Both bind-mount targets (`/.archon/.archon/workflows` and `/.archon/.archon/commands`) appear in the find output. Archon's own `archon-paths` startup log confirms `home=/.archon`, meaning it resolves user-override paths as `/.archon/.archon/workflows` — exactly where the bind mounts land. The `/app/.archon/workflows` and `/app/.archon/commands` entries are the image-bundled defaults (at the `/defaults` subdirectory level), which serve as fallback when no host override is present. Both mount targets are owned by `appuser` with owner-write permission (755). No secrets in printenv output.

---

### Test 24 — UI write-back to host bind-mount

**Status: pending** (issue #24)

Verifies that a workflow created or edited via the Archon web UI writes the YAML file back through the bind mount to the host filesystem (`.archon/workflows/`), and that the file survives a `docker compose down` / `docker compose up -d` cycle.

---

### Test 25 — OAuth token lifetime and refresh behavior

**Status: pending** (issue #25)

Verifies the `CLAUDE_CODE_OAUTH_TOKEN` lifetime when used inside the Archon container, and whether Archon or the container provides any auto-refresh mechanism before expiry.
