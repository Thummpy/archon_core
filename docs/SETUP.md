# archon-setup — First-Time Setup

## What you need before starting

- A computer running macOS, Windows 10/11, or Linux
- **A paid Claude plan (Pro, Max, Team, or Enterprise)** — required for OAuth token
  generation; the free plan will not work and is the most common setup blocker
- A web browser (for the one-time OAuth sign-in flow)
- Git installed on your machine
- About 30 minutes on first run — most of that is the Docker image download

> The OAuth token generated during setup is long-lived (approximately one year).
> Re-run `./scripts/setup-oauth.sh` only if the token is revoked.

## Why Docker?

Archon's native install requires Bun, Node.js, and OS-specific dependency resolution — a
process that has taken team members a full day to complete. Docker packages Archon and all
its dependencies into a pre-built container, reducing setup to a handful of commands
regardless of your operating system. See [`.claude/PLANNING.md`](../.claude/PLANNING.md)
Design Decisions for the full rationale.

## Step 1: Install Docker Desktop (or Docker Engine on Linux)

Docker runs Archon in an isolated container so you do not install its dependencies directly
on your machine.

**macOS:** Download and install Docker Desktop from the
[official Mac install guide](https://docs.docker.com/desktop/setup/install/mac-install/).

**Windows:** Download Docker Desktop from the
[official Windows install guide](https://docs.docker.com/desktop/setup/install/windows-install/).
Docker Desktop on Windows requires WSL 2 (Windows Subsystem for Linux 2). Once Docker
Desktop is installed, **all subsequent commands in this guide run inside WSL 2 Ubuntu** —
open a WSL 2 terminal and treat it as Linux for everything that follows.

**Linux:** Follow the
[Docker Engine install guide](https://docs.docker.com/engine/install/) for your
distribution. Docker Desktop is optional; Docker Engine plus the Compose plugin is
sufficient.

## Step 2: Verify Docker installation

Confirm Docker and the Compose v2 plugin are working:

```bash
docker --version
docker compose version
```

> **Use `docker compose` (with a space), not the v1 hyphenated form.** The space-separated
> form is the Docker Compose v2 plugin, which is the current supported version. The
> hyphenated v1 binary is deprecated and must not be used.

**What you should see:**

```
Docker version 26.x.x, build ...
Docker Compose version v2.x.x
```

The exact version numbers will vary; what matters is that both commands respond without
error.

## Step 3: Install the Claude Code CLI

The Claude Code CLI provides `claude setup-token`, which `setup-oauth.sh` calls to mint
your OAuth token. Install it with:

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

> **Windows (PowerShell — WSL 2 users skip this):**
> `irm https://claude.ai/install.ps1 | iex`. Since the rest of this guide assumes WSL 2,
> run the `curl` command above inside your WSL 2 terminal instead.

After installation, open a new terminal (or re-source your shell) and verify:

```bash
claude --version
```

**What you should see:** A version string such as `claude 1.x.x`.

## Step 4: Clone the repository

```bash
git clone git@github.com:atyeti-inc/archon-setup.git
cd archon-setup
```

This downloads the wrapper repo containing the Docker Compose configuration, custom
workflows, and operational scripts.

**What you should see:** A new `archon-setup/` directory created in your current folder.

## Step 5: Create your `.env` file

```bash
cp .env.example .env
```

`.env` holds your OAuth token and optional configuration overrides. It is excluded from git
by `.gitignore` by design — it must never be committed because it contains your
authentication credentials.

The variables available in `.env`:

| Variable | Description | How to set |
|---|---|---|
| `CLAUDE_CODE_OAUTH_TOKEN` | OAuth token for Anthropic API access | Run `./scripts/setup-oauth.sh` — it writes this automatically |
| `PORT` | Host port Archon binds to (default: `3000`) | Edit `.env` manually if port 3000 is already in use |
| `RCLONE_REMOTE` | rclone remote for cross-machine sync | Configure with `rclone config` when setting up sync (optional) |

**What you should see:** A `.env` file exists in the repo root. Running `git status` shows
no new tracked file — the entry is `.gitignore`'d.

## Step 6: Generate your OAuth token

```bash
./scripts/setup-oauth.sh
```

The script runs `claude setup-token`: a browser window opens, you sign in with your paid
Claude account, and the script writes `CLAUDE_CODE_OAUTH_TOKEN=<token>` into `.env` and
sets the file permissions to `600` (owner-read-write only). It is safe to re-run — each
invocation generates a fresh token without overwriting other `.env` keys.

> **Security note:** The OAuth token is user-scoped. Anyone with read access to `.env` on
> your machine can act as the authenticated Claude user. Disk encryption (FileVault on
> macOS, BitLocker on Windows, LUKS on Linux) is the standard mitigation. The `600`
> permissions set by the script prevent other local users from reading the file.

> **The script is intentionally strict.** It verifies that `.env.example` exists and that
> `.env` is listed in `.gitignore` before writing anything — this guards against
> accidentally committing credentials.

**What you should see:**

```
✓ CLAUDE_CODE_OAUTH_TOKEN written to /path/to/archon-setup/.env

Next: docker compose up -d
```

## Step 7: Create the data directory

```bash
mkdir -p ~/archon-data
```

Archon stores its SQLite database, workspace clones, and logs in this directory. It is
bind-mounted into the container at `/.archon` (see `docker-compose.yml`). Creating it
manually before starting Archon ensures the directory is owned by your user — on Linux, if
the directory is absent when the container starts, Docker creates it as root, which
prevents the container from writing its database.

**What you should see:**

```bash
ls -ld ~/archon-data
```

```
drwxr-xr-x  ...  <your-username>  ...  archon-data
```

Your username appears as the owner, not `root`.

## Step 8: Pull the Archon image

```bash
docker compose pull
```

This downloads the pre-built Archon container image from GHCR. The exact image tag is
pinned in `docker-compose.yml` — refer to that file for the current version rather than
a hardcoded string here. On first pull, expect 1–3 minutes depending on connection speed.

**What you should see:** Docker shows a progress bar for each layer, finishing with:

```
✔ app  Pulled
```

## Step 9: Start Archon

```bash
docker compose up -d
```

The `-d` flag runs the container in detached (background) mode. Archon's healthcheck has a
`start_period: 15s` — allow about 20 seconds for it to reach `healthy` status before
checking. To stream startup logs in real time, run `docker compose logs -f app` in a
separate terminal.

**What you should see:**

```
✔ Container archon-app  Started
```

## Step 10: Verify the install

```bash
./scripts/health.sh
```

The script performs three checks: (1) container is running — health gate; (2) `/api/health`
endpoint is responding — health gate; (3) workflow count — informational only. The first
two must pass for the script to exit successfully.

**What you should see:**

```
archon-app: running (healthy) | Archon API: OK | Workflows loaded: N
```

Then confirm the workflow overlay mount is working — your repo-managed workflows should be
visible from the host:

```bash
ls .archon/workflows/
```

**What you should see:** At least `atyeti-pev.yaml` listed. If the directory appears empty,
the bind mount may not have taken effect — see
[`docs/TROUBLESHOOTING.md`](TROUBLESHOOTING.md).

Finally, open `http://localhost:3000` in your browser to access the Archon web UI.

> **Archon is bound to `127.0.0.1:3000` (localhost only).** It is not reachable from other
> devices on the network — `http://<your-LAN-IP>:3000` will not work. This is a deliberate
> security property: binding to `0.0.0.0` would expose Archon to your local network without
> authentication.

## Next steps

- **Add or modify workflows** — see [`docs/WORKFLOW-OVERLAY.md`](WORKFLOW-OVERLAY.md) for
  how the overlay model works, how to create workflows in the UI or by hand, and how to
  share them with the team via git.
- **Daily commands** — starting, stopping, viewing logs, and restarting after a `git pull`;
  see `docs/DAILY-USE.md` (coming soon — issue #11).
- **Sync data across machines** — use `rclone` and the sync scripts; see
  `docs/SYNC-BETWEEN-MACHINES.md` (coming soon — issue #9).
- **Upgrade the pinned version** — see `docs/UPGRADING.md` (coming soon — issue #13).

## Something went wrong?

See [`docs/TROUBLESHOOTING.md`](TROUBLESHOOTING.md) for common errors and fixes.
