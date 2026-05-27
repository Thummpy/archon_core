# Upgrading Archon

## What you need before starting

- Completed [docs/SETUP.md](SETUP.md) — Archon running and healthy at least once
- Docker Desktop (or Docker Engine) running on your machine
- Repo up to date: run `git pull` from the repo root
- The version tag you want to upgrade to — find available tags at:
  - Upstream releases: `github.com/coleam00/archon/releases`
  - GHCR package page: `github.com/coleam00/archon/pkgs/container/archon`

> All commands in this guide run from the repo root directory (`archon-setup/`).

## How version pinning works

`docker-compose.yml` contains one line that determines which version of Archon runs:

```yaml
image: ghcr.io/coleam00/archon:0.3.12
```

This tag is the single source of truth. When you run `docker compose up -d`, Docker uses exactly
that version — it never pulls a newer release automatically.

To upgrade, you change the tag. `upgrade.sh` automates that process safely.

Never set the tag to `latest`. A floating tag means any `docker compose pull` could silently
change your Archon version, which may break your database schema or custom workflows without warning.

## Why backup is mandatory

**Archon has no database migration system.** When a new version of Archon starts for the first
time, it may modify the SQLite schema to match what that version expects. If the upgrade fails or
the new version is incompatible with your data, you cannot roll back without a backup — the schema
change is already in the database.

`upgrade.sh` always backs up `~/archon-data/archon.db` before changing anything. The backup is
not optional and cannot be skipped.

**Why the container must be stopped first:** SQLite uses a write-ahead log (WAL) — a staging area
for recent writes that is only fully merged into the main database file when all connections close.

`backup.sh` uses `sqlite3`'s Online Backup API (`.backup` command), which handles WAL
checkpointing internally and produces a consistent snapshot regardless of whether Archon is running.
`upgrade.sh` still stops the container before backup, but for schema migration safety: a new
Archon version may modify the database schema on first startup, and a clean stop ensures no partial
write state persists before that migration runs.

## Upgrade procedure

### Preview the upgrade (dry run)

Before upgrading, see exactly what the script will do without modifying anything:

```bash
./scripts/upgrade.sh 0.5.0 --dry-run
```

Replace `0.5.0` with your target tag.

**What you should see:**

```
→ Upgrading Archon: 0.3.12 → 0.5.0
  [dry-run] Would stop Archon (archon-app)
  [dry-run] Would back up ~/archon-data/archon.db
  [dry-run] Would update docker-compose.yml: 0.3.12 → 0.5.0
  [dry-run] Would pull ghcr.io/coleam00/archon:0.5.0
  [dry-run] Would restart Archon and validate health via scripts/health.sh
```

If this looks right, proceed with the actual upgrade.

### Run the upgrade

```bash
./scripts/upgrade.sh 0.5.0
```

The script runs six phases in order:

**Phase 1 — Stop Archon**

```
→ Stopping Archon (archon-app) via docker compose down...
✓ Archon stopped
```

Archon is stopped for schema migration safety — the new version may modify the database schema on
first startup, and a clean stop ensures no partial write state before that migration runs.

**Phase 2 — Backup the database**

```
→ Creating pre-upgrade backup...
→ Ensuring backup directory exists: /path/to/archon-setup/backups
→ Backing up database to /path/to/archon-setup/backups/archon-20241201-143022.db...
✓ Backup created: /path/to/archon-setup/backups/archon-20241201-143022.db
✓ Pre-upgrade backup complete: /path/to/archon-setup/backups/archon-20241201-143022.db
```

Note the backup path printed here — you will need it if you have to roll back.

**Phase 3 — Update the image tag**

```
→ Updating image tag in docker-compose.yml → 0.5.0
✓ Image tag updated → 0.5.0
```

The `image:` line in `docker-compose.yml` is updated in place.

**Phase 4 — Pull the new image**

```
→ Pulling new Archon image from GHCR...
✓ Image pulled successfully
```

Docker downloads the new image from GitHub Container Registry. This step requires internet access
and may take a minute depending on your connection.

**Phase 5 — Start Archon**

```
→ Starting Archon...
✓ Archon started
```

**Phase 6 — Validate health**

```
→ Validating health...
→ Checking container status (archon-app)...
✓ archon-app: running (healthy)
→ Checking API health (https://$ARCHON_DOMAIN/api/health)...
✓ Archon API: OK

✓ Upgrade complete: 0.3.12 → 0.5.0
  Backup: /path/to/archon-setup/backups/archon-20241201-143022.db
```

The upgrade is done. Archon is running the new version with your data intact.

## What happens if the upgrade fails

`upgrade.sh` exits with a code that tells you exactly what state things are in.

### Exit code 1 — Upgrade aborted, no damage

The most common failure is a failed image pull (network error, nonexistent tag, GHCR outage).
If the pull fails, `upgrade.sh` reverts `docker-compose.yml` to the original tag before exiting.
Your database is untouched. Archon was already stopped — restart it on the original version:

```bash
docker compose up -d
```

**What you should see:**

```
✔ Container archon-app  Started
```

Verify health:

```bash
./scripts/health.sh
```

### Exit code 2 — Health check failed (dangerous)

This is the critical failure case. The pull succeeded, Archon started with the new image, but the
health check failed. The new version ran long enough to potentially modify the database schema
before the health check expired. You cannot simply revert the image tag — the database may already
be incompatible with the old version.

Follow the manual rollback procedure below immediately.

## Rolling back manually

Use this procedure when `upgrade.sh` exits with code 2. The order is critical:
**restore the backup before reverting the image tag.**

**Step 1 — Stop Archon**

```bash
docker compose down
```

**What you should see:**

```
✔ Container archon-app  Stopped
✔ Container archon-app  Removed
```

**Step 2 — Restore the database backup**

Replace `<backup-path>` with the path printed during Phase 2 of the upgrade:

```bash
cp <backup-path> ~/archon-data/archon.db
```

Example:

```bash
cp backups/archon-20241201-143022.db ~/archon-data/archon.db
```

**Why this step comes first:** The new Archon version may have modified the database schema when
it started up. If you revert the image tag first, the old version would start against a
schema-modified database and fail. Restoring the backup first ensures the old version sees the
data format it understands.

**Step 3 — Revert the image tag in docker-compose.yml**

Open `docker-compose.yml` and find the `image:` line:

```yaml
image: ghcr.io/coleam00/archon:0.5.0
```

Change it back to the previous version (the version before your upgrade attempt):

```yaml
image: ghcr.io/coleam00/archon:0.3.12
```

Save the file.

**Step 4 — Restart Archon**

```bash
docker compose up -d
```

**What you should see:**

```
✔ Container archon-app  Started
```

**Step 5 — Verify health**

```bash
./scripts/health.sh
```

**What you should see:**

```
✓ archon-app: running (healthy)
✓ Archon API: OK
```

Archon is restored to the previous version with your data intact. The failed new version's image
remains cached locally but is no longer referenced — it will not run again until you upgrade again.

## Something went wrong?

See [docs/TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common errors and fixes.
