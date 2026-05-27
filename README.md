# archon_core

Docker-based deployment of [Archon](https://archon.diy) with version pinning, custom workflows, operational scripts, and team-friendly documentation.

## What Is Archon?

Archon is a workflow engine for AI coding agents. You define multi-step development workflows in YAML — plan, implement, review, open PR — and Archon orchestrates an AI assistant (Claude) to execute them against your code repositories. Interact via the **web UI**, **CLI**, or **chat adapters** (Slack, GitHub, Telegram).

Upstream docs: [archon.diy](https://archon.diy)

## What This Repo Adds

Archon's native install requires Bun, Node.js, and OS-specific dependencies. This repo wraps Archon in Docker Compose with:

- **Version pinning** — a specific GHCR image tag, not `latest`
- **Host-path volumes** — all data in `~/archon-data/`, inspectable and portable
- **Custom workflows** — version-controlled YAML in `.archon/workflows/`
- **Operational scripts** — backup, sync, upgrade, health check
- **Team docs** — step-by-step guides assuming zero Docker experience

No application code lives here — only configuration, workflows, scripts, and documentation.

## Quick Start

```bash
git clone https://github.com/Thummpy/archon_core.git
cd archon_core
./scripts/setup-oauth.sh        # generates OAuth token, writes .env
mkdir -p ~/archon-data
docker compose pull
docker compose up -d
```

Wait ~20 seconds, then verify:

```bash
./scripts/health.sh
```

Open the web UI at **https://localhost**.

First time? See [docs/SETUP.md](docs/SETUP.md) for the full walkthrough (including Docker installation).

## Using Archon (v0.3.12)

The web UI at **https://localhost** is the primary interface. The `archon` CLI binary is not in the container's PATH by design (the upstream Dockerfile does not add it), so most `docker compose exec` CLI commands are unavailable.

1. **Open the web UI** — `https://localhost` (or `http://localhost:<PORT>` if you changed it in `.env`)
2. **Add a project** — paste a repository URL in the web UI. Archon clones it into `~/archon-data/` on the host.
3. **Run a workflow** — type a natural-language request in the chat. Archon selects the matching workflow and streams progress.
4. **Build custom workflows** — use the visual builder at `/workflows/builder`. Saved workflows write YAML to `.archon/workflows/` (bind-mounted from this repo).

**Known issue:** the workflow builder stalls at ~89% if the OAuth token in `.env` has expired. Run `./scripts/setup-oauth.sh` to refresh, then retry.

For the full usage guide (logs, restart procedures, troubleshooting): [docs/DAILY-USE.md](docs/DAILY-USE.md)

## Cloud Deployment (GCP)

Deploy Archon to GCP Compute Engine VMs with Terraform — one command provisions a production-ready instance with Docker, secrets, and networking.

```bash
./scripts/terraform-init.sh     # download providers, validate config
./scripts/terraform-apply.sh    # plan, confirm, and create resources
```

See [docs/TERRAFORM-SETUP.md](docs/TERRAFORM-SETUP.md) for prerequisites and first-time setup, and [docs/GCP-DEPLOYMENT.md](docs/GCP-DEPLOYMENT.md) for the full deployment walkthrough.

## Operations

All scripts live in `scripts/` and are idempotent — safe to re-run.

| Script | Purpose | When to use |
|--------|---------|-------------|
| `setup-oauth.sh` | Generate OAuth token, write to `.env` | First-time setup or token refresh |
| `health.sh` | Check container + API + workflow count | After startup or to diagnose issues |
| `backup.sh` | WAL-safe SQLite backup to `backups/` | Before upgrades, periodically |
| `upgrade.sh` | Backup DB, bump image tag, pull, restart, validate | When updating Archon version |
| `terraform-init.sh` | Initialize Terraform, validate config | First-time Terraform setup |
| `terraform-apply.sh` | Plan and apply GCP infrastructure | Deploy or update cloud VMs |
| `terraform-destroy.sh` | Destroy all Terraform-managed resources | Tear down cloud VMs |

## Documentation

| Guide | Covers |
|-------|--------|
| [SETUP.md](docs/SETUP.md) | First-time install: Docker, OAuth, first `up` |
| [DAILY-USE.md](docs/DAILY-USE.md) | Start/stop, web UI, CLI workflows, logs, troubleshooting tips |
| [SHARING-WORKFLOWS.md](docs/SHARING-WORKFLOWS.md) | How `git pull` + restart delivers new workflows to the team |
| [WORKFLOW-OVERLAY.md](docs/WORKFLOW-OVERLAY.md) | How custom workflows coexist with Archon's built-ins |
| [SYNC-BETWEEN-MACHINES.md](docs/SYNC-BETWEEN-MACHINES.md) | *(deprecated)* rclone sync reference |
| [UPGRADING.md](docs/UPGRADING.md) | Version bump procedure with backup safety |
| [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | Common errors and fixes |
| [TERRAFORM-SETUP.md](docs/TERRAFORM-SETUP.md) | Terraform installation and GCP auth |
| [GCP-DEPLOYMENT.md](docs/GCP-DEPLOYMENT.md) | GCP VM provisioning with Terraform |

## Developing This Repo

This section covers contributing to the **wrapper repo itself** (scripts, docs, workflows), not using Archon.

Development uses Claude Code with a structured lifecycle per GitHub issue:

| Step | Command | Purpose |
|------|---------|---------|
| 0 | `/research` | *(optional)* Investigate unknowns before planning |
| 1 | `/plan-feature` | Write an implementation plan |
| 2 | `/execute` | Implement the plan step-by-step |
| 3 | `/review` | Self-review against coding standards |
| 4 | `/commit-close` | Commit, push, create PR, close issue |

Branching: GitHub Flow — feature branches off `main`, squash merge via PR.

## Team

| Role | GitHub |
|------|--------|
| Lead | [@Thummpy](https://github.com/Thummpy) |
