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

List every workflow available — Archon's 10 built-ins plus any custom workflows in `.archon/workflows/`:

```bash
docker compose exec app archon workflow list
```

`docker compose exec app` sends the command into the running container. Archon runs inside Docker, so all Archon CLI commands use this prefix.

**What you should see:** A table of workflow names and descriptions. Archon's built-in workflows:

| Workflow | Description |
|---|---|
| `archon-assist` | Answer questions about the codebase |
| `archon-fix-github-issue` | Investigate and fix a GitHub issue |
| `archon-idea-to-pr` | Turn a plain-language idea into a pull request |
| `archon-plan-to-pr` | Turn a structured plan into a pull request |
| `archon-feature-development` | End-to-end feature development |
| `archon-smart-pr-review` | Focused, targeted PR review |
| `archon-comprehensive-pr-review` | In-depth PR review with full context |
| `archon-architect` | Architectural analysis and design recommendations |
| `archon-ralph-dag` | Build a directed-acyclic graph of tasks |
| `archon-resolve-conflicts` | Resolve git merge conflicts |

These are available even when `.archon/workflows/` is empty — they ship inside the Docker image. For details on how Archon resolves custom workflows alongside built-ins, see [docs/WORKFLOW-OVERLAY.md](WORKFLOW-OVERLAY.md).

## Running a workflow from the CLI

```bash
docker compose exec app archon workflow run <name> "<message>"
```

Examples:

```bash
# Ask a question about the codebase
docker compose exec app archon workflow run archon-assist "What does the orchestrator do?"

# Fix a GitHub issue with an isolated worktree branch
docker compose exec app archon workflow run archon-fix-github-issue --branch fix/login-crash "#142"
```

Archon streams AI reasoning to the terminal as it runs. Use `--quiet` to suppress streaming output or `--verbose` for tool-level events.

Key flags:

| Flag | Description |
|---|---|
| `--branch <name>` | Create an isolated git worktree on this branch (default behavior: runs in isolated worktree) |
| `--no-worktree` | Run directly in the live checkout instead of an isolated worktree |
| `--verbose` | Stream tool-level events (file reads, writes, shell commands) |
| `--quiet` | Suppress streaming output; show only the final result |
| `--resume` | Resume an interrupted run, skipping already-completed nodes |

> **Worktree isolation is on by default.** Workflows run in isolated git worktrees at `~/.archon/workspaces/` inside the container. This keeps experiments off your main branch. Use `--no-worktree` only when you want the workflow to modify your live working directory.

Workflow name matching is fuzzy: exact → case-insensitive → suffix → substring. For example, `archon workflow run assist` resolves to `archon-assist`.

## Running a workflow from the Web UI

Open `http://localhost:3000` in your browser.

> If you changed the `PORT` variable in `.env`, use that port number: `http://localhost:<PORT>`.

The Web UI provides a chat-style interface for working with Archon. Key pages:

- **`/workflows`** — lists workflows that have a SQLite record (see note in [Listing available workflows](#listing-available-workflows))
- **`/workflows/builder`** — create or edit a workflow using the visual builder
- **`+ New Workflow`** button on the Workflows page — shortcut to the builder

## Checking workflow status

Show all currently running workflow runs:

```bash
docker compose exec app archon workflow status
```

**What you should see:** A table of active runs with run IDs, workflow names, and status. Empty output means nothing is currently running.

To resume a run that was interrupted:

```bash
docker compose exec app archon workflow resume <run-id>
```

To approve or reject a workflow at an approval gate:

```bash
docker compose exec app archon workflow approve <run-id>
docker compose exec app archon workflow reject <run-id>
```

For container-level logs when a run is missing from `status`:

```bash
docker compose logs -f app
```

## Viewing results

CLI runs stream output to the terminal in real time. The final result prints when the workflow completes.

Multi-step workflows pass output between steps using artifact files (for example, `investigation.md` or `implementation.md`). These are stored inside the workflow's worktree directory under `~/archon-data/` on your host.

Workflows that create pull requests print the PR URL on completion:

```
✓ Pull request created: https://github.com/<org>/<repo>/pull/<number>
```

Archon stores all workflow state in `~/archon-data/archon.db` (SQLite). Active worktrees live under `~/archon-data/`.

To list active worktrees or clean up stale ones:

```bash
docker compose exec app archon isolation list
docker compose exec app archon isolation cleanup
```

## Validating your setup

Run Archon's built-in diagnostic:

```bash
docker compose exec app archon doctor
```

`archon doctor` checks: binary spawn, authentication, database connectivity, workspace writability, and bundled defaults.

**What you should see:**

```
✓ binary spawn
✓ authentication
✓ database
✓ workspace write
✓ bundled defaults
```

Any `✗` line indicates a specific failure. An authentication failure usually means the OAuth token in `.env` is expired — re-run `./scripts/setup-oauth.sh` to refresh it.

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

The most common operational issue. When the OAuth token in `.env` is expired, the workflow builder stalls mid-save. The YAML file is written to `.archon/workflows/` (visible in `git status`) but the SQLite record is not written — so the workflow does not appear in the Workflows Web UI page.

To fix: run `./scripts/setup-oauth.sh` to refresh the token, then retry the save in the builder.

### Container not starting

Run `docker compose logs app` to see the error. Common causes:

- Port 3000 already in use — change `PORT` in `.env` and restart
- `~/archon-data/` owned by root — run `sudo chown -R $USER ~/archon-data` and restart

### API health check failing after startup

Wait 20 seconds and retry `./scripts/health.sh`. The healthcheck has a `start_period: 15s` before the container transitions to `healthy`. If it remains unhealthy, check `docker compose logs app` for error lines.

### Workflow not found

Run `docker compose exec app archon workflow list` to confirm the name. Name matching is fuzzy (suffix and substring), but the workflow must exist on disk or in the SQLite database. If a custom workflow is missing, confirm the YAML file is in `.archon/workflows/` and the container was restarted after the file was added.
