# Deployment

## Environments

Local only. Single environment per developer machine. Each developer runs their own Archon instance via Docker Compose on `127.0.0.1:3000`.

## Deployment Process

`docker compose up -d` is the deploy. For a fresh setup, follow the full procedure in `.claude/docs/setup.md`. For day-to-day use:

1. `docker compose pull` — pull the latest pinned image (only needed after version bump)
2. `docker compose up -d` — start or recreate containers
3. `./scripts/health.sh` — verify the container is healthy and the API responds

## Rollback Procedure

1. Edit `docker-compose.yml` to revert the image tag to the previous version
2. Pull and restart: `docker compose pull && docker compose up -d`
3. If the database schema changed between versions, restore from backup:
   ```bash
   cp backups/archon-YYYYMMDD-HHMMSS.db ~/archon-data/archon.db
   docker compose restart app
   ```
4. Verify: `./scripts/health.sh`

## Monitoring & Alerts

- **Health check:** `./scripts/health.sh` checks container status and the `/api/health` endpoint
- **Container logs:** `docker compose logs -f app` for real-time log streaming
- **Docker status:** `docker compose ps` to see container state and uptime
- No external monitoring dashboards or alert channels — this is a local development tool

## Access & Credentials

- **OAuth token:** Stored in `.env` file (`.gitignore`'d). Generated via `./scripts/setup-oauth.sh` using `claude setup-token`. Authenticates against Anthropic API using the developer's Max subscription.
- **No rotation schedule** — OAuth tokens from Max subscription are long-lived. Regenerate via `./scripts/setup-oauth.sh` if needed.
- **No shared credentials** — each developer has their own `.env` with their own token.
- **PostgreSQL credentials** (optional profile only): Set via `DATABASE_URL` in `.env`. Only relevant when using `docker compose --profile with-db`.
