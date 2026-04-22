# Project Planning

## Project Overview

archon-setup is a wrapper repository that provides one-command Docker-based setup for Archon, a rapidly evolving open-source harness builder. It serves Chris (Atyeti CDO/CAIO) and Atyeti developers who need a turnkey local Archon installation without wrestling with Bun, Node.js, and OS-specific dependency resolution. The project pins a specific Archon version from GHCR, owns custom workflows in version control, and enables portable data across machines via host-path volumes and rclone sync.

## Architecture

Wrapper repo pattern. The repo contains no application code — only Docker Compose configuration, custom Archon workflow/command YAML files, operational Bash scripts, and beginner-friendly documentation. Archon runs as a pre-built Docker image pulled from GHCR (`ghcr.io/coleam00/archon:{tag}`). All persistent state lives in `~/archon-data/` on the host filesystem, making it inspectable, syncable, and independent of the container lifecycle. See `.claude/docs/architecture.md` for diagrams and component details.

## Tech Stack

- **Language:** Bash (scripts), YAML (Docker Compose, workflow definitions), Markdown (command files, documentation)
- **Framework:** Docker Compose v2 (container orchestration)
- **Database:** SQLite (Archon's default, zero config, stored at `~/archon-data/archon.db`)
- **Infrastructure:** Docker, Docker Compose — local only
- **Tools:** `claude` CLI (OAuth token generation), `rclone` (cross-machine sync), `gh` CLI (optional, GitHub integration), `jq` (optional, JSON processing)

## Design Decisions

- **Docker over native install** — Native Archon install requires Bun, Node.js, and OS-specific dependency resolution. A team member spent a full day on it. Docker reduces setup to 4 commands regardless of OS.
- **Host-path volume over named Docker volume** — Named volumes are opaque (managed by Docker, hidden path). Host-path at `~/archon-data/` makes the data a regular folder that can be inspected (`ls`, `sqlite3`), backed up (`cp`), and synced (`rclone`). Trade-off: slightly less portable Docker Compose (path is hardcoded), but the portability gain of syncable data outweighs it.
- **SQLite over PostgreSQL as default** — Zero additional config, no extra container, no credentials to manage. Sufficient for single-user local use. Postgres available as optional `with-db` profile for anyone who needs it.
- **rclone over Dropbox/Syncthing/manual rsync** — rclone supports 40+ cloud providers (Google Drive, S3, Dropbox, etc.), has a mature CLI, and handles OAuth for Drive natively. Single tool covers all sync destinations.
- **OAuth over API key** — Max subscription provides fixed-cost billing. For power users running multiple workflows daily, API billing would be significantly more expensive.
- **Read-only volume mounts for workflows/commands** — Prevents the container from modifying harness definitions. The repo is the source of truth; the container consumes it.
- **Docs as first-class deliverable** — The target audience includes developers who may not know Docker. Bad docs = support tickets to Chris. Good docs = self-service onboarding.

## Constraints

- **HARD: No fork of Archon.** All customization via configuration, YAML workflows, Markdown commands, and volume mounts.
- **HARD: `.env` never committed.** Contains OAuth token. `.env.example` provides the template.
- **HARD: Stop Archon before syncing.** SQLite does not handle concurrent writers. `sync-up.sh` and `sync-down.sh` enforce `docker compose down` before sync.
- **Archon's database has no migration system.** Schema changes between versions may require database recreation. The upgrade script backs up `archon.db` before proceeding and validates health after.

## Style & Conventions

- **Version pin is the source of truth.** The GHCR image tag in `docker-compose.yml` is the single definition of which Archon version is running. Never use `latest` or track a branch.
- **Custom workflows override by filename.** A file in `.archon/workflows/` with the same name as an Archon default replaces it. Use distinct names for additive workflows.
- **All scripts are idempotent and narrate.** Every script prints what it's about to do before doing it, handles "already done" gracefully, and exits non-zero on failure with a human-readable message.
- **Docs assume zero Docker knowledge.** Every doc explains what each command does and why, not just what to type. Include "what you should see" after each step.
- **Workflow YAML files must include a `description:` field** at the top level for discoverability by Archon's skill system and the vscode-archon extension.

## Out of Scope

- Modifying Archon's source code or forking the repo
- Cloud deployment (GCP, AWS, etc.) — local Docker only. Cloud is a future decision.
- Building the vscode-archon extension (separate project, separate seed)
- Multi-user authentication or team access controls on the Archon instance
- Archon Web UI customization
- Custom Docker image builds — we consume the upstream GHCR image as-is
