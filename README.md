# archon-setup

Wrapper repository for a version-pinned local Archon installation with custom workflows, OAuth authentication, portable data via host-path volumes, and team-friendly documentation for developers with minimal Docker experience.

## Why This Exists

Archon is a rapidly evolving open-source harness builder (TypeScript/Bun) that publishes Docker images to GHCR. Installing from source requires Bun, Node.js, and OS-specific dependency resolution — a process that has taken team members a full day. This wrapper repo provides one-command Docker-based setup, pins a specific version, owns custom workflows in version control, and enables portable data across machines.

## Tech Stack

- **Docker Compose v2** — container orchestration
- **Bash** — operational scripts (setup, sync, upgrade, health)
- **YAML** — Docker Compose config + Archon workflow definitions
- **SQLite** — Archon's default database (zero config)
- **rclone** — cross-machine data sync (optional)

## Getting Started

```bash
git clone git@github.com:atyeti-inc/archon-setup.git
cd archon-setup
cp .env.example .env
./scripts/setup-oauth.sh
mkdir -p ~/archon-data
docker compose pull
docker compose up -d
```

See [docs/SETUP.md](docs/SETUP.md) for detailed step-by-step instructions (including Docker installation for first-time users).

## Architecture

Wrapper repo pattern — no application code, only configuration, workflows, scripts, and docs. Archon runs as a pre-built Docker container from GHCR. All data lives in `~/archon-data/` on the host, making it inspectable, syncable, and independent of the container.

See [.claude/docs/architecture.md](.claude/docs/architecture.md) for diagrams and component details.

## Roadmap

| Phase | Focus | Goal |
|-------|-------|------|
| 1 | Vertical slice | Clone → 4 commands → working Archon with PEV workflow |
| 2 | Sync & portability | rclone setup, sync scripts, work on any machine |
| 3 | Team workflow library | Standard Atyeti modalities (ML, data, web, docs, infra) |
| 4 | Operational hardening | Upgrade scripts, troubleshooting, optional Postgres |

## Development Workflow

| Command | Purpose |
|---------|---------|
| `/research` | Iterative pre-plan research to resolve unknowns |
| `/plan-feature` | Research codebase and generate an implementation plan |
| `/execute` | Implement the plan step-by-step with validation |
| `/review` | Self-review changes against standards |
| `/commit-close` | Validate, commit, push, create PR, and close issue |
| `/handoff` | Save session state when context is heavy but task is not done |
| `/compact` | Compress context for long-running sessions |

## Team

| Role | GitHub Handle |
|------|---------------|
| Lead | @Thummpy |
