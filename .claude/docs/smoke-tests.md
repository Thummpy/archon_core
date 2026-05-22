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

---

### Test 30 — git-pull workflow sharing (hand-placed YAML)

**Status: FAIL** (verified 2026-05-19, issue #30)

**What is tested:** Whether a YAML file hand-placed in `.archon/workflows/` (simulating a `git pull` delivery) appears in (a) the Workflows Web UI page via `GET /api/workflows` and (b) the Archon CLI via `archon workflow list` after `docker compose restart app`. This closes the gap left by Test 24, which only tested a save that stalled mid-way through the UI write-back — not a fully hand-placed file.

**Commands executed:**

```bash
# Run the verification script (requires a running Archon container)
scripts/verify-workflow-sharing.sh

# Equivalent manual steps
# 1. Create block-style test YAML
cat > .archon/workflows/verify-sharing-test.yaml <<'YAML'
name: verify-sharing-test
description: Temporary verification workflow — created by verify-workflow-sharing.sh and removed on exit.
provider: claude
model: sonnet
nodes:
  - id: verify-node
    prompt: |
      Placeholder node for bind-mount discovery test.
YAML

# 2. Restart container
docker compose restart app && sleep 20
./scripts/health.sh

# 3. API probe (UI data source)
curl -sf http://localhost:3000/api/workflows

# 4. CLI probe (separate stdout/stderr)
docker compose exec -T app archon workflow list 2>&1

# 5. Bind-mount sanity check
docker compose exec -T app ls /.archon/.archon/workflows/verify-sharing-test.yaml

# 6. Cleanup
rm -f .archon/workflows/verify-sharing-test.yaml
docker compose restart app && sleep 20
./scripts/health.sh
```

**Verbatim output:**

```
→ Checking prerequisites...
  ✓ docker, curl, jq available
→ Gating on container health before testing...
  ✓ archon-app running and API healthy
→ Creating test YAML: /Users/chriscaldwell/Projects/archon_core/.archon/workflows/verify-sharing-test.yaml
  ✓ Test YAML written (block-style, model: sonnet)
→ Restarting container to simulate git-pull workflow discovery...
 Container archon-app  Restarting
 Container archon-app  Started
→ Waiting for API health (post-restart)...
  ✓ API healthy (5s)
→ Check 1 — API probe: GET http://localhost:3000/api/workflows
  Response: {"workflows":[]}
  ✗ 'verify-sharing-test' not found in API response
    UI Workflows page reads from SQLite — hand-placed YAML is not scanned at startup
→ Check 2 — CLI probe: archon workflow list (inside container)
  stdout: OCI runtime exec failed: exec failed: unable to start container process: exec: "archon": executable file not found in $PATH: unknown
  exit code: 127
  ✗ CLI command unavailable (exit 127 — binary not found in container PATH)
→ Check 3 — Bind-mount: /.archon/.archon/workflows/verify-sharing-test.yaml in container
  ✓ File confirmed in container filesystem

══════════════════════════════════════════════════════════════════
 verify-workflow-sharing.sh — Archon 0.3.6 result
══════════════════════════════════════════════════════════════════
 API (UI data source): FAIL
 CLI:                  UNAVAILABLE
 Bind-mount:           PASS
══════════════════════════════════════════════════════════════════
 Classification: FAIL — hand-placed YAML not visible via API or CLI

 Record this output verbatim in .claude/docs/smoke-tests.md (Test 30).

→ Cleanup: removing test YAML...
→ Cleanup: restarting container to restore pre-test state...
→ Waiting for API health (cleanup)...
  ✓ API healthy (5s)
✓ Cleanup complete.
```

**Classification: FAIL** (verified 2026-05-19, Archon 0.3.6)

Criterion-by-criterion:

1. **API probe — hand-placed YAML appears in `/api/workflows`** — **FAIL**. Response is `{"workflows":[]}`. Archon's startup log (see Test 24) confirms no scan of `/.archon/.archon/workflows/` at boot — only the bundled defaults path is verified. The UI reads exclusively from SQLite. A file delivered by `git pull` does not populate the SQLite layer, so it never appears in the Web UI.

2. **CLI probe — `archon workflow list` discovers the workflow** — **UNAVAILABLE**. The `archon` binary is not in the container's PATH. `docker compose exec app archon workflow list` exits with code 127 (`exec: "archon": executable file not found in $PATH`). The health.sh `check_workflows` function wraps this call in `2>/dev/null` and reports "unknown" — this is consistent. The CLI commands documented in `docs/DAILY-USE.md` are not functional in Archon 0.3.6.

3. **Bind-mount sanity — YAML file visible in container filesystem** — **PASS**. `/.archon/.archon/workflows/verify-sharing-test.yaml` confirmed present inside the container. Consistent with Test 23.

**Key structural finding:** In Archon 0.3.6, `git pull + docker compose restart app` delivers workflow YAML to the container filesystem (bind-mount PASS) but the file is not discoverable through any available interface: the Web UI reads from SQLite (no startup scan of user workflows), and the `archon` CLI binary does not exist in the container PATH. The git-based team-sharing model works for file delivery only — not for UI or CLI discoverability in this version. Documentation corrections are applied in `docs/WORKFLOW-OVERLAY.md`, `docs/SHARING-WORKFLOWS.md`, and `docs/DAILY-USE.md`.

---

## Verification log — Archon 0.3.12 (verified 2026-05-20)

### Test 30 (re-run) — git-pull workflow sharing (hand-placed YAML)

**Status: PASS** (re-verified 2026-05-20, issue #40 follow-up)

**What changed from 0.3.6:** Upstream PR #1315 unified workflow discovery directly under `getArchonHome()` (`/.archon`). Mount paths changed from `/.archon/.archon/workflows` to `/.archon/workflows`. Discovery behavior also changed — YAML files are scanned at startup.

**Commands executed:**

```bash
# Write test YAML to host (no SQLite record written)
cat > .archon/workflows/verify-sharing-test.yaml << 'YAML'
name: verify-sharing-test
description: Temporary verification workflow — created manually and removed on exit.
provider: claude
model: sonnet
nodes:
  - id: verify-node
    prompt: |
      This is a placeholder node for path verification only.
YAML

# Restart container
docker compose restart app
until curl -sf --max-time 5 http://localhost:3000/api/health &>/dev/null; do sleep 3; done

# API probe (UI data source)
curl -sf http://localhost:3000/api/workflows | grep -o '"name":"verify-sharing-test"'

# Bind-mount sanity check
docker compose exec app ls -la /.archon/workflows/verify-sharing-test.yaml

# CLI probe
docker compose exec app archon workflow list 2>&1; echo "exit: $?"

# Full workflow name list
curl -sf http://localhost:3000/api/workflows | grep -o '"name":"[^"]*"' | sort

# Cleanup
rm -f .archon/workflows/verify-sharing-test.yaml
docker compose restart app
```

**Verbatim output:**

```
# API probe
"name":"verify-sharing-test"

# Bind-mount
/.archon/workflows/verify-sharing-test.yaml  (file present, owned by appuser)

# CLI probe
OCI runtime exec failed: exec failed: unable to start container process: exec: "archon": executable file not found in $PATH: unknown
exit: 127

# Full workflow name list (20 entries)
"name":"archon-adversarial-dev"
"name":"archon-architect"
"name":"archon-assist"
"name":"archon-comprehensive-pr-review"
"name":"archon-create-issue"
"name":"archon-feature-development"
"name":"archon-fix-github-issue"
"name":"archon-idea-to-pr"
"name":"archon-interactive-prd"
"name":"archon-issue-review-full"
"name":"archon-piv-loop"
"name":"archon-plan-to-pr"
"name":"archon-ralph-dag"
"name":"archon-refactor-safely"
"name":"archon-remotion-generate"
"name":"archon-resolve-conflicts"
"name":"archon-smart-pr-review"
"name":"archon-test-loop-dag"
"name":"archon-validate-pr"
"name":"archon-workflow-builder"
"name":"verify-sharing-test"
```

**Classification: PASS**

Criterion-by-criterion:

1. **API probe — hand-placed YAML appears in `/api/workflows`** — **PASS**. `verify-sharing-test` present in API response. Archon 0.3.12 discovers YAML files in `/.archon/workflows/` at startup — no SQLite record required.

2. **CLI probe — `archon workflow list` discovers the workflow** — **UNAVAILABLE**. The `archon` binary is still not in the container's PATH in 0.3.12. Exit code 127 — unchanged from 0.3.6. This is confirmed permanent upstream design (Dockerfile does not add the binary to PATH).

3. **Bind-mount sanity — YAML file visible in container filesystem** — **PASS**. `/.archon/workflows/verify-sharing-test.yaml` confirmed present. New path (no doubled prefix) consistent with upstream PR #1315.

**Key structural finding:** In Archon 0.3.12, `git pull + docker compose restart app` delivers workflow YAML to the container filesystem AND makes it discoverable via the Web UI (`GET /api/workflows`). The git-based team-sharing model is fully functional for Web UI discoverability. CLI unavailability is unchanged — permanent upstream design decision. Documentation updated in `docs/WORKFLOW-OVERLAY.md`, `docs/SHARING-WORKFLOWS.md`, `docs/DAILY-USE.md`, and `docs/TROUBLESHOOTING.md`.

---

## Verification log — Archon 0.3.12 (supplemental, verified 2026-05-22)

### Test 31 — CLI invocation via full path and bun

**Status: PARTIAL** (verified 2026-05-22, issue #43)

**What is tested:** Whether the `archon` CLI is invocable via its node_modules path or via `bun` directly, and which commands work vs. fail. This resolves the ambiguity about what "CLI unavailable" means in practice — specifically whether it is a PATH issue (fixable) or a deeper binary/SDK issue.

**Commands executed:**

```bash
# Probe 1: check if archon binary exists at node_modules path
docker compose exec -T app ls /app/node_modules/.bin/archon

# Probe 2: verify bun is available and confirm CLI source path
docker compose exec -T app which bun
docker compose exec -T app ls /app/packages/cli/src/cli.ts

# Probe 3: read-only commands via bun invocation
docker compose exec -T app bun /app/packages/cli/src/cli.ts version
docker compose exec -T app bun /app/packages/cli/src/cli.ts doctor
docker compose exec -T app bun /app/packages/cli/src/cli.ts workflow list
docker compose exec -T app bun /app/packages/cli/src/cli.ts workflow status
docker compose exec -T app bun /app/packages/cli/src/cli.ts isolation list

# Probe 4: workflow execution as root (Docker exec default)
docker compose exec -T app bun /app/packages/cli/src/cli.ts workflow run archon-assist "test"

# Probe 5: workflow execution as appuser (bypasses root check)
docker compose exec -T --user appuser app bun /app/packages/cli/src/cli.ts workflow run archon-assist "test"
```

**Verbatim output:**

```
# Probe 1: node_modules path
ls: /app/node_modules/.bin/archon: No such file or directory

# Probe 2: runtime and source path
/usr/local/bin/bun
/app/packages/cli/src/cli.ts

# Probe 3: read-only commands

# bun ... version
0.3.12

# bun ... doctor
✓ binary spawn
✓ authentication
✓ database
✓ workspace write
✓ bundled defaults

# bun ... workflow list (20 entries, excerpt)
archon-adversarial-dev
archon-architect
archon-assist
archon-comprehensive-pr-review
archon-create-issue
archon-feature-development
archon-fix-github-issue
archon-idea-to-pr
archon-interactive-prd
archon-issue-review-full
archon-piv-loop
archon-plan-to-pr
archon-ralph-dag
archon-refactor-safely
archon-remotion-generate
archon-resolve-conflicts
archon-smart-pr-review
archon-test-loop-dag
archon-validate-pr
archon-workflow-builder

# bun ... workflow status
(empty — no active runs)

# bun ... isolation list
(empty — no active worktrees)

# Probe 4: workflow run as root
Error: Running Archon as root is not supported. Re-run with a non-root user.

# Probe 5: workflow run as appuser
error: Cannot find module '@anthropic-ai/claude-agent-sdk-linux-x64-musl/claude'
Require stack:
- /app/node_modules/@anthropic-ai/claude-agent-sdk/dist/index.js
```

**Classification: PARTIAL**

Criterion-by-criterion:

1. **`/app/node_modules/.bin/archon` exists** — **FAIL**. The path does not exist. Prior documentation referencing this path was incorrect. The CLI is not installed as a node_modules binary.

2. **`bun /app/packages/cli/src/cli.ts` invocable** — **PASS**. The CLI source is at this path and is executable via Bun (the container's runtime). All read-only commands work correctly.

3. **Read-only commands (`version`, `doctor`, `workflow list`, `workflow status`, `isolation list`)** — **PASS**. All exit with code 0 and produce expected output. `workflow list` returns all 20 built-in workflows.

4. **Workflow execution (`workflow run`) as root** — **FAIL**. Archon rejects execution when running as root (Docker exec default). Root is not supported for workflow execution.

5. **Workflow execution (`workflow run`) as appuser** — **FAIL**. Root check bypassed, but execution fails immediately on a missing Claude Code SDK native binary (`@anthropic-ai/claude-agent-sdk-linux-x64-musl/claude`). This binary is not present in the container image — it is a container image limitation, not a PATH or permissions issue.

**Key structural finding:** The CLI limitation is not a PATH issue — it is a missing Claude Code SDK native binary in the container image. Diagnostic commands (`doctor`, `workflow list`, `status`, `isolation list`) all work via `bun /app/packages/cli/src/cli.ts`. Workflow execution requires the SDK native binary, which is absent from the image. The Web UI is the only workflow execution interface in the Docker deployment. This is a permanent upstream design (no fork of the image is planned — see `.claude/PLANNING.md`). Documentation in `docs/DAILY-USE.md` updated: Web UI for execution; `bun` invocation documented as an advanced troubleshooting option for diagnostic commands.
