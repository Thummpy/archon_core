# Troubleshooting

## What you need before starting

- The archon-setup repository cloned on your machine
- A terminal open in the repo root directory (`archon-setup/`)

> Commands below assume you are in the repo root. Most fixes involve re-running a script
> or restarting the container — no special tools beyond what SETUP.md already installed.

Find the error message or behavior you see below, then follow the fix.

> For upgrade failures specifically, see the rollback procedure in
> [docs/UPGRADING.md](UPGRADING.md#rolling-back-manually).

---

## Docker not running

**Symptom:** Any script or `docker compose` command fails with:

```
Cannot connect to the Docker daemon at unix:///var/run/docker.sock
```

**Cause:** Docker Desktop (macOS/Windows) is not running, or Docker Engine (Linux) is stopped.

**Fix:**

- **macOS / Windows:** Open Docker Desktop from your Applications folder (or Start menu). Wait
  for the whale icon in the menu bar to stop animating before retrying.
- **Linux:** Run `sudo systemctl start docker`

Verify Docker is up:

```bash
docker info
```

This should return engine details without error.

---

## Container won't start

**Symptom:** `docker compose up -d` exits with an error, or the container starts and immediately
exits.

**Diagnosis:** Check the container logs:

```bash
docker compose logs app
```

**Common causes:**

**Port already in use:**

```
Error response from daemon: Ports are not available: ... address already in use
```

Another process is using port 3000. Change the port in `.env`:

```
PORT=3001
```

Then restart:

```bash
docker compose up -d
```

**Data directory owned by root:**

```
chown: changing ownership of '/.archon': Permission denied
```

Docker created `~/archon-data/` as root during a previous run (usually when a `docker compose`
command was run with `sudo`). Fix the ownership:

```bash
sudo chown -R $USER ~/archon-data
```

Then restart:

```bash
docker compose up -d
```

---

## API health check failing

**Symptom:** `./scripts/health.sh` reports:

```
✗ Archon API: unreachable (http://localhost:3000/api/health)
```

**Cause:** Most of the time this is a timing issue. Archon's Docker healthcheck has a
`start_period: 15s` — the container reports `starting` for the first 15 seconds regardless of
actual readiness, and Archon itself needs a few additional seconds to initialize.

**Fix:**

1. Wait 20 seconds after starting, then re-run `./scripts/health.sh`.
2. If still failing, check the logs: `docker compose logs app`
3. If the logs show crash output, see "Container won't start" above.
4. If PORT in `.env` differs from 3000, export it before running health.sh:
   `PORT=3001 ./scripts/health.sh` (or set it in your shell environment).

---

## OAuth token expired

**Symptom:** One or both of:

- The workflow builder save stalls at approximately 89% and never completes
- CLI operations fail with authentication errors

**Cause:** The `CLAUDE_CODE_OAUTH_TOKEN` in `.env` has expired. The workflow YAML file is written
to `.archon/workflows/` (you can see it in `git status`), but the SQLite record is not written, so
the workflow does not appear in the Workflows Web UI page.

**Fix:** Refresh the token — a browser window will open for you to sign in:

```bash
./scripts/setup-oauth.sh
```

Then restart Archon to pick up the new token from `.env`:

```bash
docker compose down && docker compose up -d
```

Do not manually paste a token value into `.env` — always use `setup-oauth.sh` to generate and
write it safely.

---

## Database not found

**Symptom:** `./scripts/backup.sh` (or any script that calls it) fails with:

```
✗ Database not found: /Users/you/archon-data/archon.db
  Has Archon been started? Try: docker compose up -d
```

**Cause:** Archon creates `archon.db` on its first startup. If Archon has never run on this
machine, the file does not exist yet.

**Fix:** Start Archon and let it initialize:

```bash
docker compose up -d
```

Wait 20 seconds, then verify it is healthy:

```bash
./scripts/health.sh
```

Once healthy, re-run the backup script.

---

## sqlite3 not found

**Symptom:** `./scripts/backup.sh` (or any script that calls it) fails with:

```
✗ Required tool not found: sqlite3
  macOS (pre-installed): brew install sqlite3
  Ubuntu/WSL:            sudo apt install sqlite3
```

**Cause:** `backup.sh` uses `sqlite3`'s Online Backup API to create WAL-safe backups. `sqlite3`
ships pre-installed on macOS but requires manual installation on Debian/Ubuntu and WSL.

**Fix:**

- **macOS:** `sqlite3` ships pre-installed. If missing, reinstall with:
  ```bash
  brew install sqlite3
  ```
- **Ubuntu / WSL:** Install with:
  ```bash
  sudo apt update && sudo apt install sqlite3
  ```

Verify the installation:

```bash
sqlite3 --version
```

Once installed, re-run the backup script.

---

## Upgrade health check failed (exit code 2)

**Symptom:** `./scripts/upgrade.sh` exits with code 2 and prints:

```
✗ Health check failed after upgrade. Manual rollback steps:
  ...
```

**Cause:** The new Archon version started but its API did not pass the health check. The new
version may have modified the SQLite database schema on startup, making a simple tag revert
unsafe.

**Fix:** Follow the 5-step rollback procedure in
[docs/UPGRADING.md — Rolling back manually](UPGRADING.md#rolling-back-manually).

The critical detail: **restore the database backup (step 2) before reverting the image tag
(step 3)**. The new version may have already modified the schema — restoring the backup first
ensures the old version sees data it understands.

---

## Sync failed — rclone remote not configured

**Symptom:** `./scripts/sync-up.sh` or `./scripts/sync-down.sh` fails with:

```
✗ rclone remote 'gdrive:' is not configured. Run: rclone config
```

**Cause:** The rclone remote referenced in `RCLONE_REMOTE` (default: `gdrive:archon-data`) has
not been configured on this machine.

**Fix:** Run the rclone configuration wizard:

```bash
rclone config
```

Select "New remote", choose your provider type (e.g., `drive` for Google Drive), and complete the
browser OAuth flow. See [docs/SYNC-BETWEEN-MACHINES.md](SYNC-BETWEEN-MACHINES.md) for full
step-by-step rclone setup instructions.

---

## Sync failed — other rclone errors

**Symptom:** The sync script starts, reaches the rclone transfer step, then fails with a transfer
error (not the "remote not configured" message above).

**Common causes:**

- Network connectivity issues during the transfer
- Expired cloud storage OAuth token (common with Google Drive after several months)
- Remote storage quota exceeded

**Diagnosis:** Test connectivity to the remote directly:

```bash
rclone lsd gdrive:
```

Replace `gdrive` with your remote name. If this command fails, the problem is with the remote
connection, not with Archon.

**Fix — re-authenticate the remote:**

```bash
rclone config reconnect gdrive:
```

Or run `rclone config` and select the existing remote to reconfigure it from scratch.

---

## Permission denied on ~/archon-data

**Symptom:** The Archon container fails to start and `docker compose logs app` shows:

```
chown: changing ownership of '/.archon': Permission denied
```

**Cause:** `~/archon-data/` was created as root, usually because a `docker compose` command was
run with `sudo` earlier. The container entrypoint runs `chown` over `/.archon` (the volume mount)
and exits fatally if it lacks permission.

**Fix:**

```bash
sudo chown -R $USER ~/archon-data
```

Then restart:

```bash
docker compose up -d
```

**What you should see:**

```
✔ Container archon-app  Started
```

---

## Workflow not appearing after git pull

**Symptom:** You pulled a workflow YAML file and restarted the container, but the workflow does
not appear in the CLI or Web UI.

**Checklist:**

1. **Confirm the file exists on disk:**

   ```bash
   ls .archon/workflows/
   ```

2. **Restart the container after the pull** (a pull alone does not reload files):

   ```bash
   docker compose restart app
   ```

3. **Check the YAML has a `description:` field.** Open the file and verify the top-level keys
   include `description:`. Archon's workflow discovery system skips files without this field.

4. **In 0.3.12, the workflow should appear in the Web UI after restart.** Archon
   discovers YAML files at startup (confirmed — see [`.claude/docs/smoke-tests.md`](../.claude/docs/smoke-tests.md) Test 30). Open `http://localhost:3000/workflows`
   to confirm. The `archon` CLI binary is not in the container PATH by design — `archon workflow
   list` exits with code 127. You can also verify filesystem delivery with:

   ```bash
   docker compose exec app ls /.archon/workflows/
   ```

   The file being present in that listing confirms the bind-mount delivered it correctly.

---

## Bind mount appears empty

**Symptom:** Commands run inside the container do not see files from `.archon/workflows/` or
`.archon/commands/`.

**Cause:** The host directory may be empty, or files were added to the host after the container
started without a restart. Archon resolves its config paths relative to its home directory
(`/.archon`), which maps to `~/archon-data/` on the host — but the workflows and commands are
separate bind mounts (`/.archon/workflows`), not subdirectories of that volume.

**Fix:**

1. Verify the host directory has files:

   ```bash
   ls .archon/workflows/
   ```

2. Restart the container to pick up any changes:

   ```bash
   docker compose restart app
   ```

3. Verify the files are visible inside the container:

   ```bash
   docker compose exec app ls /.archon/workflows/
   ```

---

## Still stuck?

Open an issue at [github.com/Thummpy/archon_core/issues](https://github.com/Thummpy/archon_core/issues)
and include:

- The exact command you ran
- The full error output (copy-paste, not a screenshot)
- Your OS and Docker version: `docker --version`
