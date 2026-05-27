# Production Deployment

> **Deploying to GCP?** See [GCP-DEPLOYMENT.md](GCP-DEPLOYMENT.md) for the complete walkthrough covering OAuth setup, Terraform-managed infrastructure, GitHub Actions configuration, and day-to-day operations.

## What you need before starting

- Completed [docs/SETUP.md](SETUP.md) — local development environment working
- A GCP VM running Ubuntu with Docker and Docker Compose installed (see [Infrastructure Setup](#infrastructure-setup))
- SSH access to the production VM
- Repository admin access to configure GitHub secrets

> Production deployment is automatic on every push to `main` via GitHub Actions. Manual deployment is available via the Actions UI.

## How Deployment Works

When code is pushed to `main`, the GitHub Actions workflow:

1. **Connects** to the production GCP VM via SSH
2. **Pulls** the latest code from the `main` branch
3. **Updates** Docker images to the pinned version in `docker-compose.yml`
4. **Restarts** containers with `docker compose up -d` (zero-config update)
5. **Verifies** container health and API availability

**Data safety:** The workflow **never touches** `~/archon-data/` on the VM. All database files, OAuth tokens, and user data persist across deployments.

## Prerequisites

### Infrastructure Setup

Before configuring deployment, you need:

- **GCP VM** — Ubuntu 22.04+ with Docker Engine and Docker Compose v2 installed
- **SSH key** — Private key authorized for `chris` user on the VM
- **Git repository** — Cloned at `~/archon_core` on the VM with `main` branch checked out

> See related PRs for infrastructure details:
> - PR #54: Terraform configuration for GCP VM
> - PR #55: Caddy and OAuth2 Proxy setup

### GitHub Secrets Configuration

The deployment workflow requires two secrets configured in GitHub:

1. **DEPLOY_SSH_KEY** — Private SSH key for authenticating to the VM
2. **DEPLOY_HOST** — IP address or hostname of the GCP VM

## Step 1: Generate or Locate SSH Key

If you don't have an SSH key for the `chris` user on the VM:

```bash
# On your local machine
ssh-keygen -t ed25519 -C "github-actions-deploy" -f ~/.ssh/gcp_deploy_key
```

Copy the **public** key to the VM:

```bash
ssh-copy-id -i ~/.ssh/gcp_deploy_key.pub chris@<VM_IP>
```

Test the connection:

```bash
ssh -i ~/.ssh/gcp_deploy_key chris@<VM_IP>
```

**What you should see:** A successful SSH connection to the VM without password prompt.

## Step 2: Configure GitHub Secrets

Navigate to your repository on GitHub → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**.

Create two secrets:

### DEPLOY_SSH_KEY

- **Name:** `DEPLOY_SSH_KEY`
- **Secret:** Paste the **entire contents** of the private key file (`~/.ssh/gcp_deploy_key`)

```bash
# Copy private key contents to clipboard
cat ~/.ssh/gcp_deploy_key | pbcopy  # macOS
cat ~/.ssh/gcp_deploy_key | xclip -selection clipboard  # Linux
```

### DEPLOY_HOST

- **Name:** `DEPLOY_HOST`
- **Secret:** The IP address or hostname of your GCP VM (e.g., `34.123.45.67`)

**What you should see:** Both secrets listed in the repository secrets page (values are hidden).

## Step 3: Verify VM Configuration

SSH into the production VM and confirm the repository is set up:

```bash
ssh chris@<VM_IP>
```

On the VM:

```bash
cd ~/archon_core
git status
docker compose version
```

**What you should see:**

```
On branch main
Your branch is up to date with 'origin/main'.

Docker Compose version v2.x.x
```

If the repository doesn't exist at `~/archon_core`, clone it:

```bash
cd ~
git clone git@github.com:Thummpy/archon_core.git
cd archon_core
```

## Step 4: Test Deployment

### Automatic Deployment (Push to Main)

Merge a PR to `main` or push directly:

```bash
git push origin main
```

Watch the deployment in GitHub Actions:

1. Navigate to your repository → **Actions** tab
2. Click the latest "Deploy" workflow run
3. Monitor the "Deploy to GCP VM via SSH" step

**What you should see:**

```
→ Checking required tools
✓ All required tools available
→ Navigating to project directory
→ Pulling latest code from main
→ Verifying git state after pull
→ Pulling latest Docker images
→ Restarting containers with new images
→ Waiting for containers to stabilize (5s)
→ Verifying container health
→ Verifying API health
✓ Deployment complete - API is healthy
```

### Manual Deployment (Workflow Dispatch)

Trigger a deployment manually:

1. Navigate to **Actions** tab → **Deploy** workflow
2. Click **Run workflow** → Select `main` branch → **Run workflow**

This is useful for:
- Redeploying after VM restart
- Testing deployment without pushing code
- Forcing a container restart

## Verifying Deployment Success

After deployment completes, verify the application is running:

```bash
# On the VM
./scripts/health.sh
```

**What you should see:**

```
archon-app: running (healthy) | Archon API: OK | Workflows loaded: N
```

Check the running containers:

```bash
docker compose ps
```

**What you should see:**

```
NAME          IMAGE                              STATUS
archon-app    ghcr.io/coleam00/archon:<tag>      Up ... (healthy)
```

## Rollback

If a deployment fails or introduces issues:

1. **Identify the last known good commit:**

   ```bash
   gh pr list --state merged --limit 5
   ```

2. **Revert the commit locally:**

   ```bash
   git revert <bad-commit-sha>
   git push origin main
   ```

   This triggers automatic deployment of the reverted state.

3. **Alternatively, manually roll back on the VM:**

   ```bash
   ssh chris@<VM_IP>
   cd ~/archon_core
   git reset --hard <good-commit-sha>
   docker compose pull
   docker compose up -d
   ```

## Deployment Logs

View deployment logs in GitHub Actions:

1. Navigate to **Actions** tab
2. Click the relevant workflow run
3. Expand the "Deploy to GCP VM via SSH" step

View application logs on the VM:

```bash
ssh chris@<VM_IP>
cd ~/archon_core
docker compose logs -f app
```

## Troubleshooting

### Deployment workflow fails with "Permission denied (publickey)"

**Cause:** DEPLOY_SSH_KEY secret is incorrect or the public key is not authorized on the VM.

**Fix:**
1. Verify the private key matches the public key on the VM
2. Check `~/.ssh/authorized_keys` on the VM contains the correct public key
3. Update DEPLOY_SSH_KEY secret in GitHub if needed

### Deployment succeeds but containers don't restart

**Cause:** `docker compose up -d` failed silently or containers are already running with the same image.

**Fix:**
1. SSH into the VM and check `docker compose ps`
2. Manually restart: `docker compose down && docker compose up -d`
3. Check logs: `docker compose logs app`

### API health check fails after deployment

**Cause:** Container started but application crashed, port conflict, or database migration failure.

**Fix:**
1. Check container logs: `docker compose logs app --tail=100`
2. Verify port availability: `netstat -tlnp | grep 3000`
3. Check database state: `docker compose exec app ls -lh ~/archon-data/`
4. Roll back to last known good commit (see [Rollback](#rollback))

### Workflow runs on every push but I only want main

**Cause:** Workflow is correctly configured. It only runs on pushes to `main`.

**Fix:** No action needed. Feature branches do not trigger deployment.

## Something went wrong?

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues and fixes.
