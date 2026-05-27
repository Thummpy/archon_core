# Daily Use

## What you need before starting

- Completed [docs/SETUP.md](SETUP.md) — Archon container image pulled, `.env` configured with a valid `CLAUDE_CODE_OAUTH_TOKEN`
- Docker Desktop (or Docker Engine) running on your machine

> All commands in this guide run from the repo root directory (`archon-setup/`).

## Starting Archon

Start Archon in the background:

```bash
docker compose up -d
```

`docker compose up -d` starts the container in detached mode (background). Docker does not pull a new image on this command — it uses the pinned image tag already on disk.

**What you should see:**

```
✔ Container archon-app  Started
```

Archon's healthcheck has a `start_period: 15s` — wait about 20 seconds before checking health. To stream startup logs in real time while waiting, run `docker compose logs -f app` in a separate terminal.

## Stopping Archon

```bash
docker compose down
```

`docker compose down` stops the container and removes it. All data is stored in `~/archon-data/` on your machine — stopping the container does not delete anything. Use `docker compose down` before running sync scripts, before upgrading, or to free resources.

To stop without removing the container (preserves it for faster restart with `docker compose start`):

```bash
docker compose stop
```

## Checking health

After starting, run the health check script to confirm everything is working:

```bash
./scripts/health.sh
```

The script checks three things: the container is running, the `/api/health` endpoint responds, and workflow count (informational). The first two must pass.

**What you should see:**

```
archon-app: running (healthy) | Archon API: OK | Workflows loaded: N
```

If `Archon API: unreachable`, wait a few more seconds and retry — the healthcheck has a 15-second start period before the container is marked `healthy`.

You can also check container status directly:

```bash
docker compose ps
```

**What you should see:**

```
NAME          IMAGE                              STATUS
archon-app    ghcr.io/coleam00/archon:<tag>      Up ... (healthy)
```

The `<tag>` matches the pinned version in `docker-compose.yml`.

## Viewing logs

Stream logs from the Archon container:

```bash
docker compose logs -f app
```

`-f` tails the log in real time. Press `Ctrl+C` to stop streaming. Remove `-f` to print existing logs and exit.

**What you should see on a healthy startup:**

```
archon-app  | [INFO] Archon started
archon-app  | [INFO] Listening on port 3000
```

Errors appear as `[ERROR]` lines. If Archon fails to start, the container logs are the first place to look.

## Listing available workflows

Browse available workflows in the Web UI at `https://localhost/workflows`. Your browser may show a self-signed certificate warning on first visit — accept it to proceed (see [docs/SETUP.md](SETUP.md) Step 12 for details). You will be prompted to sign in via Google OAuth before accessing the UI. In 0.3.12, this page shows both built-in workflows and any custom YAML files in `.archon/workflows/` — no CLI required.

> **`archon workflow list` not available.** The `archon` binary is not in the container's PATH by design — the upstream Dockerfile does not add it, so the command exits with code 127.

Archon's built-in workflows in 0.3.12 (verified 2026-05-20):

| Workflow | Trigger / purpose |
|---|---|
| `archon-adversarial-dev` | Build a complete application from scratch using adversarial development |
| `archon-architect` | Architectural sweep, complexity reduction, or system design |
| `archon-assist` | General-purpose — use when no other workflow matches |
| `archon-comprehensive-pr-review` | Comprehensive code review of a pull request |
| `archon-create-issue` | Report a bug or problem as a GitHub issue |
| `archon-feature-development` | Implement a feature from an existing plan |
| `archon-fix-github-issue` | Fix, resolve, or implement a solution for a GitHub issue |
| `archon-idea-to-pr` | Feature idea or description → end-to-end pull request |
| `archon-interactive-prd` | Create a PRD through guided conversation |
| `archon-issue-review-full` | Full fix + review pipeline for a GitHub issue |
| `archon-piv-loop` | Guided Plan-Implement-Validate development loop |
| `archon-plan-to-pr` | Existing implementation plan → execute as pull request |
| `archon-ralph-dag` | Ralph implementation loop (directed acyclic graph) |
| `archon-refactor-safely` | Refactor code safely with continuous validation |
| `archon-remotion-generate` | Generate or modify a Remotion video composition |
| `archon-resolve-conflicts` | Resolve merge conflicts in a pull request |
| `archon-smart-pr-review` | Efficient PR review that adapts to PR size and complexity |
| `archon-test-loop-dag` | Test loop DAG (triggered by explicit command) |
| `archon-validate-pr` | Thorough PR validation testing both main branch and PR |
| `archon-workflow-builder` | Create a new custom workflow for a project |

These are available even when `.archon/workflows/` is empty — they ship inside the Docker image. For details on how Archon resolves custom workflows alongside built-ins, see [docs/WORKFLOW-OVERLAY.md](WORKFLOW-OVERLAY.md).

## Running a workflow

Workflow execution requires the Web UI — the `archon` CLI binary is not in the container PATH by design (the upstream Dockerfile does not add it), so `archon workflow run` exits with code 127.

Open `https://localhost` in your browser.

> Archon is accessed via `https://localhost` through Caddy and OAuth2 Proxy. Accept the self-signed certificate warning on first visit.

**How to run a workflow:**

1. Open `https://localhost` in your browser.
2. Navigate to the **Workflows** page (sidebar or `/workflows`).
3. Click the workflow you want to run — for example, `archon-assist` for general tasks or `archon-fix-github-issue` for GitHub issue work.
4. Type your request or task description in the chat input and press **Run** (or **Enter**).

**What you should see:** Archon streams its reasoning and tool calls in real time as the workflow progresses. The final result appears when the workflow completes. Workflows that create pull requests print the PR URL in the output.

Key pages in the Web UI:

- **`/workflows`** — lists all available workflows (built-in + any custom YAML files in `.archon/workflows/`)
- **`/workflows/builder`** — create or edit a workflow using the visual builder
- **`+ New Workflow`** button on the Workflows page — shortcut to the builder

## Checking workflow status

All active workflow runs are visible in the Web UI at `https://localhost`. Click a run to see its current status, live output, and any pending approval gates. Resume, approve, and reject operations are also handled in the Web UI — the `archon workflow resume/approve/reject` CLI commands are not available in the container.

For container-level logs — useful when a run is not appearing in the Web UI or you want the raw output stream:

```bash
docker compose logs -f app
```

**What you should see:** Each line is prefixed with `archon-app  |`. Running workflows emit reasoning and tool-call lines in real time. Press `Ctrl+C` to stop streaming. Remove `-f` to print existing logs and exit immediately.

## Viewing results

Workflow output streams in the Web UI in real time. The final result appears when the workflow completes.

Multi-step workflows pass output between steps using artifact files (for example, `investigation.md` or `implementation.md`). These are stored inside the workflow's worktree directory under `~/archon-data/` on your host.

Workflows that create pull requests show the PR URL in the output on completion:

```
✓ Pull request created: https://github.com/<org>/<repo>/pull/<number>
```

Archon stores all workflow state in `~/archon-data/archon.db` (SQLite). Active worktrees live under `~/archon-data/`.

To inspect active worktrees inside the container:

```bash
docker compose exec app ls /.archon/workspaces/
```

**What you should see:** A list of workspace directory names, one per active workflow run. Each directory is an isolated git worktree. Check the Web UI for active run status before removing anything manually.

## Validating your setup

Run the health check script as your primary diagnostic:

```bash
./scripts/health.sh
```

**What you should see:**

```
archon-app: running (healthy) | Archon API: OK | Workflows loaded: 20
```

The script checks three things: the container is running, the `/api/health` endpoint responds, and the workflow count (informational). If any gate fails, the script explains what to fix. See [docs/TROUBLESHOOTING.md](TROUBLESHOOTING.md) for detailed error recovery.

> **Advanced — internal health checks:** For low-level diagnostics (database connectivity, workspace writability, bundled defaults), use Bun to invoke the CLI source directly inside the container:
>
> ```bash
> docker compose exec -T app bun /app/packages/cli/src/cli.ts doctor
> ```
>
> **What you should see:**
> ```
> ✓ binary spawn
> ✓ authentication
> ✓ database
> ✓ workspace write
> ✓ bundled defaults
> ```
>
> Any `✗` line indicates a specific failure. An authentication failure usually means the OAuth token in `.env` is expired — re-run `./scripts/setup-oauth.sh` to refresh it. This uses Bun (the container's runtime) to call the CLI source — the `archon` binary is not in the container PATH by design.

## Restarting after configuration changes

After changes that do not require a full stop — for example, a `git pull` that added new workflows, an edit to `.env`, or a change to `.archon/config.yaml`:

```bash
docker compose restart app
```

`restart` stops and starts the container in place. It is faster than a full `down`/`up` cycle and does not re-pull the image.

After changes that require a full stop — for example, before running a sync script or after modifying volume mounts in `docker-compose.yml`:

```bash
docker compose down
docker compose up -d
```

`down` removes the container. `up -d` recreates it from the current `docker-compose.yml`.

## Something went wrong?

See [docs/TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common errors and fixes.

### Save stalling at ~89% in the workflow builder

The most common operational issue. When the OAuth token in `.env` is expired, the workflow builder stalls mid-save. The YAML file is written to `.archon/workflows/` (visible in `git status`) but the SQLite record is not written — in 0.3.12, the YAML on disk is still discoverable: a `docker compose restart app` surfaces the workflow in the Workflows Web UI immediately.

To fix: run `docker compose restart app` to make the workflow visible right away. Then run `./scripts/setup-oauth.sh` to refresh the token and retry the save in the builder to write the complete SQLite record.

### Container not starting

Run `docker compose logs app` to see the error. Common causes:

- Port 3000 already in use — change `PORT` in `.env` and restart
- `~/archon-data/` owned by root — run `sudo chown -R $USER ~/archon-data` and restart

### API health check failing after startup

Wait 20 seconds and retry `./scripts/health.sh`. The healthcheck has a `start_period: 15s` before the container transitions to `healthy`. If it remains unhealthy, check `docker compose logs app` for error lines.

### Workflow not found

Open `https://localhost/workflows` — in 0.3.12, this page shows all available workflows including built-ins and any custom YAML files in `.archon/workflows/`. To confirm the file reached the container filesystem:

```bash
docker compose exec app ls /.archon/workflows/
```

If a custom workflow is missing, confirm the YAML file is in `.archon/workflows/` on your host and that you restarted the container after adding it:

```bash
docker compose restart app
```
