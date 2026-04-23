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

**Status: PARTIAL** (issue #24, verified 2026-04-23)

**What is tested:** Whether a workflow authored in the Archon 0.3.6 web UI at `http://localhost:3000` writes a YAML file back through the `/.archon/.archon/workflows` bind-mount to the host filesystem (`.archon/workflows/`), and whether that file survives `docker compose restart app` and remains visible in the UI listing.

**UI navigation observed (operator):** Top nav → "Workflows" (`/workflows`) → "+ New Workflow" button → Workflow Builder (`/workflows/builder`). The builder required more than the issue spec's `description: + steps: []`: a provider (`claude`), a model string, and at least one node before Save was accepted.

**Commands executed:**

```bash
# Preflight
command -v docker && docker compose version    # → Docker Compose version v2.40.3
grep -cE '^CLAUDE_CODE_OAUTH_TOKEN=.+' .env   # → 1
docker info >/dev/null 2>&1 && echo "daemon OK"  # → daemon OK

# Bring up
docker compose up -d && sleep 20
./scripts/health.sh
# → archon-app: running (healthy) | Archon API: OK | Workflows loaded: unknown

# Baseline check
ls -la .archon/workflows/           # → only .gitkeep; git status clean

# [OPERATOR] Created workflow in UI builder with:
#   name:        smoke-test
#   description: "Smoke test for issue #24 - UI write-back verification"
#   provider:    claude
#   model:       claude-sonnet-4-6
#   nodes:       1 node — "This is a smoke test prompt. it does nothing. Ping (pong)."
# Clicked Save → progress bar stalled at ~89% indefinitely

# File appearance check (polled within 30s of Save click)
ls -la .archon/workflows/           # → smoke-test.yaml, 253 bytes, appeared within ~5s
cat .archon/workflows/smoke-test.yaml
git status .archon/workflows/       # → smoke-test.yaml listed as untracked

# Container-side confirmation (bind-mount verified)
docker compose exec -T app ls -la /.archon/.archon/workflows/
# → smoke-test.yaml 253 bytes (same file, same ownership as host)

# Restart persistence
docker compose restart app && sleep 20
./scripts/health.sh                             # → running (healthy) | API: OK
ls -la .archon/workflows/smoke-test.yaml        # → still 253 bytes, unchanged
cat .archon/workflows/smoke-test.yaml           # → identical content

# [OPERATOR] Checked http://localhost:3000/workflows → "No workflows found.
#   Add workflow definitions to .archon/workflows/"

# API probe (UI's data source)
curl -sf http://localhost:3000/api/workflows    # → {"workflows":[]}

# Startup log key lines (post-restart)
# {"module":"archon-paths","home":"/.archon","msg":"paths_configured"}
# {"module":"archon-paths","workflows":"/app/.archon/workflows/defaults","msg":"app_defaults_verified"}
# NO log line scanning /.archon/.archon/workflows/ — only bundled defaults scanned at startup

# Bundled default schema (for comparison with UI-generated file)
docker compose exec -T app head -6 /app/.archon/workflows/defaults/archon-adversarial-dev.yaml
# → name: archon-adversarial-dev
#    provider: claude
#    model: sonnet    ← short alias, not full API ID
#    nodes:
#      - id: plan
#        prompt: |

# Cleanup
rm -f .archon/workflows/smoke-test.yaml
docker compose restart app && sleep 20
./scripts/health.sh     # → healthy
ls -la .archon/workflows/  # → only .gitkeep
git status              # → clean (only untracked: .claude/prps/24.md)
```

**Verbatim output (key excerpts):**

```
# File on host after UI save
-rw-r--r--  1 chriscaldwell  staff  253 Apr 23 12:59 smoke-test.yaml

# File content (flow-style YAML as written by UI builder)
{name: smoke-test,description: "Smoke test for issue #24 - UI write-back verification",provider: claude,model: claude-sonnet-4-6,nodes: [{id: node-f76b3add-ced7-494a-ba34-26560ee6338d,prompt: This is a smoke test prompt. it does nothing. Ping (pong).}]}

# File inside container (bind-mount confirmed)
-rw-r--r-- 1 appuser appuser 253 Apr 23 16:59 smoke-test.yaml

# API probe result
{"workflows":[]}

# Startup log — archon-paths module (no user-workflow scan path)
{"module":"archon-paths","home":"/.archon","workspaces":"/.archon/workspaces","worktrees":"/.archon/worktrees","config":"/.archon/config.yaml","msg":"paths_configured"}
{"module":"archon-paths","commands":"/app/.archon/commands/defaults","workflows":"/app/.archon/workflows/defaults","msg":"app_defaults_verified"}
```

**Classification: PARTIAL**

Criterion-by-criterion against issue #24 acceptance criteria:

1. **Create `smoke-test.yaml` in UI with `description:` and `steps: []`** — PARTIAL. Workflow builder found at `Workflows → + New Workflow`. File created, but UI requires provider, model, and ≥1 node beyond the issue-spec minimum. The UI uses a `nodes:` key (not `steps:`).

2. **`ls -la .archon/workflows/smoke-test.yaml` within 30 seconds** — **PASS**. File appeared within ~5 seconds at 253 bytes. Bind-mount write-back is real and fast.

3. **Workflow still lists in UI after restart** — **FAIL**. The save stalled at ~89%: Archon makes an outbound Claude API call during save (model validation or workflow compilation). That call hung — likely because `CLAUDE_CODE_OAUTH_TOKEN` is not usable by Archon (see issue #25). The SQLite record was never written. Archon's Workflows UI page reads from `/api/workflows` (SQLite-backed), not from YAML files in `/.archon/.archon/workflows/`. The startup log confirms Archon does not scan `/.archon/.archon/workflows/` at startup — only the bundled `/app/.archon/workflows/defaults/` is verified. No combination of restart or presence of the YAML file made the workflow appear in the UI.

4. **`rm -f .archon/workflows/smoke-test.yaml && docker compose restart app` — cleanup** — **PASS** (trivially — the workflow was never in the UI). File deleted cleanly; container restarted healthy; git working tree clean.

5. **Document actual persistence mechanism if UI does not write to host** — N/A. The UI **does** write to the host bind-mount (criterion 2 PASS). However, the UI listing reads from SQLite layer, not the YAML file. The two-layer model is: (a) YAML written via bind-mount to `/.archon/.archon/workflows/` — confirmed working; (b) SQLite record written via an Archon API call that also triggers an outbound Claude API call — blocked by hung API call in this session.

**Key structural finding:** Archon 0.3.6's workflow persistence is two-layer. The UI save writes (a) a YAML file to the bind-mount path and (b) a SQLite record to `archon.db`. The UI Workflows page reads only from layer (b). A save that hangs at ~89% completes layer (a) but not layer (b). The git-sharing model — `git pull + docker compose restart app` delivers UI-authored workflows to teammates — is **unverified**: Archon does not scan `/.archon/.archon/workflows/` at startup to populate layer (b) from layer (a) YAML files. Whether hand-placed YAML files appear in the UI listing is a separate open question. Follow-up: see issue #30.

---

### Test 25 — OAuth token lifetime and refresh behavior

**Status: pending** (issue #25)

Verifies the `CLAUDE_CODE_OAUTH_TOKEN` lifetime when used inside the Archon container, and whether Archon or the container provides any auto-refresh mechanism before expiry.
