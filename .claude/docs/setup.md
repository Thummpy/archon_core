# Setup

## Prerequisites

- **Docker Desktop** (Mac/Windows) or **Docker Engine + Docker Compose v2** (Linux)
- **A Claude Pro/Max/Team/Enterprise subscription** — needed for OAuth token generation
- **A web browser** — for the one-time OAuth login flow
- **Git** — to clone the repository and share workflow updates

Optional tools (installed as needed):

- **`rclone`** — only needed for cross-machine data sync (Phase 2)
- **`gh` CLI** — only needed for workflows that interact with GitHub issues/PRs

## Clone & Install

```bash
git clone git@github.com:atyeti-inc/archon-setup.git
cd archon-setup
cp .env.example .env
./scripts/setup-oauth.sh    # Installs claude CLI if needed, runs setup-token, writes to .env
mkdir -p ~/archon-data       # Create host data directory
docker compose pull
docker compose up -d
```

## Environment Configuration

All configuration lives in the `.env` file. Copy `.env.example` to `.env` and fill in the values:

| Variable | Description | How to Obtain |
|----------|-------------|---------------|
| `CLAUDE_CODE_OAUTH_TOKEN` | OAuth token for Anthropic API authentication | Run `./scripts/setup-oauth.sh` — it handles installation and token generation |
| `PORT` | Archon app port (default: `3000`) | Set manually if port 3000 is in use |
| `RCLONE_REMOTE` | rclone remote name for sync scripts (default: `gdrive:archon-data`) | Configure with `rclone config` when setting up cross-machine sync |
| `DATABASE_URL` | PostgreSQL connection string | Only needed with `--profile with-db`. Omit for default SQLite. |

The `.env` file is `.gitignore`'d and must never be committed — it contains your OAuth token.

## Local Development

```bash
# Start Archon
docker compose up -d

# Access Web UI at http://localhost:3000

# View logs
docker compose logs -f app

# Restart after pulling new workflows
git pull && docker compose restart app

# Stop Archon
docker compose down

# Start with optional PostgreSQL
docker compose --profile with-db up -d
```

## Verify Setup

```bash
./scripts/health.sh
# Expected output: "archon-app: healthy | Archon API: OK | Workflows loaded: N"
```
