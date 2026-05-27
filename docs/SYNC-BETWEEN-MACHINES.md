> **DEPRECATED:** This document describes rclone sync functionality that was removed in favor of OAuth2-protected local-only deployment. The sync scripts (`sync-up.sh`, `sync-down.sh`) no longer exist. This document is kept for historical reference only.

---

# Sync Between Machines

## What you need before starting

- Archon running on at least one machine (see [docs/SETUP.md](SETUP.md) to get started)
- [rclone](https://rclone.org/install/) installed on each machine you want to sync
- A Google Drive account (or any [rclone-supported provider](https://rclone.org/overview/))
- About 15 minutes for first-time rclone setup per machine

> The sync scripts check for `docker` and `rclone` at startup and print install instructions if either is missing.

## Why sync?

Archon stores all its state — the SQLite database, workspace clones, and logs — in `~/archon-data/` on your machine. If you work across multiple machines (a laptop at a client site and a desktop at home), you need that folder on both. The sync scripts use rclone to copy `~/archon-data/` to and from cloud storage so you can pick up exactly where you left off on any machine.

## How it works

```
Machine A  →  ./scripts/sync-up.sh  →  Cloud Storage  →  ./scripts/sync-down.sh  →  Machine B
```

- `sync-up.sh` stops Archon, backs up the database, and copies `~/archon-data/` to the configured rclone remote. Archon stays down after sync (you are done with this machine).
- `sync-down.sh` stops Archon, downloads from the remote, and restarts Archon (you just arrived).
- **Archon must be stopped before syncing.** SQLite — the database Archon uses — writes changes to a write-ahead log (WAL) that is only fully checkpointed when all connections close. Copying the database while Archon is running produces a corrupt or inconsistent replica. Both scripts run `docker compose down` automatically before transferring any data.

> **One-directional, not merge.** `rclone sync` makes the destination match the source exactly. If both machines have local changes, whichever ran last wins. Always sync up from the machine you just worked on before syncing down on another — otherwise the older changes are lost.

## Step 1: Install rclone

**macOS:**

```bash
brew install rclone
```

**Linux:**

```bash
sudo apt-get install rclone
```

For other platforms or the latest version, see the [rclone install guide](https://rclone.org/install/).

Verify the installation:

```bash
rclone version
```

**What you should see:**

```
rclone v1.x.x
- os/version: ...
```

The exact version number will vary. What matters is that the command responds without error.

## Step 2: Configure a Google Drive remote

Run the interactive configuration wizard:

```bash
rclone config
```

Follow the prompts in order:

1. Type `n` and press Enter to create a new remote.
2. Enter `gdrive` as the remote name — this matches the default path used by the sync scripts.
3. When asked for the storage type, type `drive` and press Enter. Do not type a number; numeric positions shift between rclone versions and `drive` is stable.
4. Press Enter to leave `client_id` blank — uses rclone's built-in OAuth credentials.
5. Press Enter to leave `client_secret` blank.
6. When asked for the scope, select `drive.file`. This restricts rclone to files it created — it cannot read your other Google Drive content. In most rclone versions this is listed as option 3, but the number may vary; look for `drive.file` in the description.
7. Press Enter to accept defaults for `root_folder_id` and `service_account_file`.
8. When asked to edit advanced config, press Enter (No).
9. When asked to use auto config, press Enter (Yes). A browser window opens at `http://127.0.0.1:53682/auth` for Google OAuth consent.
10. Sign in with your Google account and grant rclone the requested access. The browser shows "Success" when complete.
11. When asked if this is a Shared Drive, press Enter (No).
12. Confirm the remote summary looks correct and press Enter or type `y` to save.
13. Type `q` to quit the configuration wizard.

> **Headless or SSH machines.** If you are running rclone on a machine without a browser, skip the auto-config step. On a machine that does have a browser, run `rclone authorize "drive"` and complete the OAuth flow. Copy the token it prints. Back on the headless machine, paste it when rclone prompts for the token during `rclone config`.

Verify the remote was created:

```bash
rclone listremotes
```

**What you should see:**

```
gdrive:
```

## Step 3: Set RCLONE_REMOTE in .env (optional)

The sync scripts resolve the rclone destination in this order: shell environment variable → `.env` file → built-in default `gdrive:archon-data`. If you named your remote `gdrive` and the folder in Google Drive should be called `archon-data`, the default works and this step is optional.

To use a different remote name or folder path, add this line to your `.env` file:

```
RCLONE_REMOTE=gdrive:archon-data
```

Replace `gdrive` with your remote name and `archon-data` with the destination folder path.

> **Do not commit `.env`.** It contains your OAuth token and is `.gitignore`'d by design. The `.env.example` file shows the variable name as a template — never copy credentials into `.env.example`.

## Step 4: Upload your data (sync-up)

Run this command from the repo root:

```bash
./scripts/sync-up.sh
```

The script stops Archon, creates a timestamped backup of `archon.db` in `backups/`, and syncs `~/archon-data/` to the remote. Archon stays down after the sync — you are leaving this machine.

**What you should see:**

```
→ Remote: gdrive:archon-data
→ Verifying rclone remote 'gdrive:' is configured...
✓ Remote 'gdrive:' found
→ Stopping Archon (archon-app) via docker compose down...
✓ Archon stopped
→ Creating pre-sync backup...
✓ Pre-sync backup complete: /path/to/backups/archon-20260518-143022.db
→ Syncing /Users/you/archon-data → gdrive:archon-data...
✓ Sync complete in 12s

✓ sync-up complete in 15s → gdrive:archon-data
```

To stay on this machine and keep working after the sync, add `--restart`:

```bash
./scripts/sync-up.sh --restart
```

To preview what would be transferred without transferring anything:

```bash
./scripts/sync-up.sh --dry-run
```

## Step 5: Download on another machine (sync-down)

On the destination machine, complete Steps 1–3 first (install rclone, configure the remote, optionally set `RCLONE_REMOTE`). You can also copy `~/.config/rclone/rclone.conf` from the source machine instead of re-running `rclone config` — just do not commit or share this file, as it contains your OAuth token.

Then run:

```bash
./scripts/sync-down.sh
```

The script verifies the remote and then asks you to confirm the destructive operation before doing anything:

```
→ Remote: gdrive:archon-data
→ Verifying rclone remote 'gdrive:' is configured...
✓ Remote 'gdrive:' found

WARNING: This will OVERWRITE /Users/you/archon-data with contents of gdrive:archon-data.
  Local DB: /Users/you/archon-data/archon.db (42M)

Type YES to proceed:
```

> **Data loss warning.** Typing `YES` replaces everything in `~/archon-data/` with the remote contents. Any local data on this machine that was not first uploaded with `sync-up.sh` will be permanently deleted. If you have unsaved local work, run `sync-up.sh` on this machine before proceeding.

Type `YES` (uppercase, exactly) and press Enter to proceed:

```
→ Stopping Archon (archon-app) via docker compose down...
✓ Archon stopped
→ Ensuring data directory exists: /Users/you/archon-data
✓ Data directory ready
→ Syncing gdrive:archon-data → /Users/you/archon-data...
✓ Sync complete in 18s
→ Starting Archon...
→ Validating health...
archon-app: running (healthy) | Archon API: OK | Workflows loaded: N

✓ sync-down complete in 25s ← gdrive:archon-data
```

Open `http://localhost:3000` to confirm Archon is running.

To skip the interactive confirmation (for use in scripts or automation):

```bash
./scripts/sync-down.sh --yes
```

To download the data without restarting Archon:

```bash
./scripts/sync-down.sh --no-restart
```

To preview what sync-down would transfer without actually downloading anything:

```bash
./scripts/sync-down.sh --dry-run
```

> **`--dry-run` still triggers the confirmation prompt and still stops/restarts Archon.** Only the rclone transfer is skipped — Archon goes through a full stop-and-restart cycle. To preview with minimal disruption, combine all three flags:
>
> ```bash
> ./scripts/sync-down.sh --dry-run --yes --no-restart
> ```

**What you should see** (with `--dry-run --yes --no-restart`):

```
→ Remote: gdrive:archon-data
→ Verifying rclone remote 'gdrive:' is configured...
✓ Remote 'gdrive:' found
→ Stopping Archon (archon-app) via docker compose down...
✓ Archon stopped
→ Ensuring data directory exists: /Users/you/archon-data
✓ Data directory ready
→ Syncing gdrive:archon-data → /Users/you/archon-data...
Transferred:        0 B / 0 B, -, 0 B/s, ETA -
✓ Sync complete in 2s

✓ sync-down complete in 5s ← gdrive:archon-data
```

No files are transferred. Archon stays down (because of `--no-restart`). Start it again with `docker compose up -d` when you are ready.

## Common scenarios

### Leaving for the day (laptop → cloud)

You are done working on your laptop and want the data available on your desktop.

```bash
./scripts/sync-up.sh
```

Archon stops, data uploads, Archon stays down. The laptop is safe to close.

### Arriving at another machine (cloud → desktop)

You are at your desktop and want to continue where you left off on your laptop.

```bash
./scripts/sync-down.sh
```

Confirm the overwrite with `YES`. Data downloads and Archon starts automatically. Open `http://localhost:3000` when the script finishes.

## Something went wrong?

See [`docs/TROUBLESHOOTING.md`](TROUBLESHOOTING.md) for common errors and fixes.
