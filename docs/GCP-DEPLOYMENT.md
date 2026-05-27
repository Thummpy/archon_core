# GCP Deployment — Complete Walkthrough

How to deploy Archon to a GCP VM with OAuth2 authentication, automated GitHub Actions deploys, and TLS via Caddy. This guide covers everything from creating your GCP project to day-to-day operations.

**Prerequisite:** Complete [TERRAFORM-SETUP.md](TERRAFORM-SETUP.md) first — it covers installing Terraform, Google Cloud SDK, authenticating with GCP, and initializing the Terraform workspace.

## What you need before starting

- **Terraform initialized** — `./scripts/terraform-init.sh` ran successfully (see [TERRAFORM-SETUP.md](TERRAFORM-SETUP.md))
- **Google Cloud SDK** authenticated — `gcloud auth application-default login` completed
- **A GCP project** with billing enabled
- **Your secret values ready:** Claude OAuth token, GitHub token, Discord bot token
- **A Google account** for OAuth2 sign-in (the email you'll use to access Archon)
- About **45–60 minutes** for first-time setup

> **Operational knowledge:** See [INFRASTRUCTURE-ISSUES.md](INFRASTRUCTURE-ISSUES.md) for documented gotchas (Terraform heredoc escaping, Docker permissions, startup timing) that may save debugging time during deployment.

### Understanding terraform.tfvars

Before you begin, you need `terraform/terraform.tfvars` populated. Copy the example and edit it:

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
```

Here's what each variable does:

| Variable | What it does | Example |
|----------|-------------|---------|
| `gcp_project_id` | The GCP project where all resources are created. Find it in the GCP Console dashboard or run `gcloud projects list`. | `"my-archon-project"` |
| `oauth_email` | The Google email address allowed to sign in to Archon via OAuth2 Proxy. Only this email can access the web UI. | `"you@gmail.com"` |
| `archon_instances` | A map of Archon instances to deploy. Each key becomes the SSH username and names the VM. The `secrets_map` inside points to GCP Secret Manager secret **names** (not the secret values). | See below |

```hcl
gcp_project_id = "my-archon-project"
oauth_email    = "you@gmail.com"

archon_instances = {
  chris = {
    secrets_map = {
      claude_oauth_token = "archon-chris-claude-oauth-token"
      github_token       = "archon-chris-github-token"
      discord_bot_token  = "archon-chris-discord-bot-token"
    }
  }
}
```

The `secrets_map` values are the **names** you'll give your secrets in GCP Secret Manager (Step 3). Terraform reads the secret values at deploy time using these names. The map key (`chris` in this example) becomes your SSH username and is used in resource naming.

> **Discord bot auto-start:** The Discord bot service starts automatically with `docker compose up -d`. If you don't need Discord integration, you can leave `discord_bot_token` as an empty string in Secret Manager (create the secret with value `""`), or see [DISCORD-BOT-SETUP.md](DISCORD-BOT-SETUP.md) for opt-out instructions. For full Discord setup, complete [DISCORD-BOT-SETUP.md](DISCORD-BOT-SETUP.md) before deploying to GCP.

## Step 1: Set Up Google OAuth Client

Archon uses OAuth2 Proxy with Google authentication to protect the web UI. You need to create OAuth2 credentials in the Google Cloud Console before deploying.

1. Go to [Google Cloud Console — Credentials](https://console.cloud.google.com/apis/credentials)
2. Select your GCP project from the dropdown at the top
3. If prompted to configure the OAuth consent screen first:
   - User type: **External** (or Internal if using Google Workspace)
   - App name: `Archon`
   - User support email: your email
   - Authorized domains: leave blank for now
   - Developer contact: your email
   - Click **Save and Continue** through the remaining screens
4. Click **Create Credentials** → **OAuth client ID**
5. Application type: **Web application**
6. Name: `Archon OAuth2 Proxy`
7. Under **Authorized redirect URIs**, click **Add URI** and enter a placeholder:
   ```
   https://placeholder.sslip.io/oauth2/callback
   ```
   You'll update this with your actual IP after Terraform creates the VM (Step 7).
8. Click **Create**

**What you should see:**

A dialog showing your **Client ID** and **Client Secret**. Copy both values and save them securely — you'll need them when configuring OAuth2 on the VM (Step 5).

> **Why a placeholder URI?** The actual static IP is assigned by Terraform in Step 4. You'll come back to update the redirect URI with the real domain in Step 6.

## Step 2: Enable GCP APIs

Terraform needs Compute Engine, Secret Manager, and IAM APIs enabled in your project:

```bash
gcloud services enable compute.googleapis.com --project=YOUR_PROJECT_ID
gcloud services enable secretmanager.googleapis.com --project=YOUR_PROJECT_ID
gcloud services enable iam.googleapis.com --project=YOUR_PROJECT_ID
```

Replace `YOUR_PROJECT_ID` with your actual GCP project ID (the same value as `gcp_project_id` in terraform.tfvars).

**What you should see:**

```
Operation "operations/..." finished successfully.
```

If an API is already enabled, the command succeeds silently — it is safe to re-run.

## Step 3: Create Secrets in Secret Manager

Create a secret for each credential. The secret **names** must match the values in your `terraform.tfvars` `secrets_map`.

```bash
echo -n "your-claude-oauth-token" | \
  gcloud secrets create archon-chris-claude-oauth-token \
    --data-file=- --project=YOUR_PROJECT_ID

echo -n "your-github-token" | \
  gcloud secrets create archon-chris-github-token \
    --data-file=- --project=YOUR_PROJECT_ID

echo -n "your-discord-bot-token" | \
  gcloud secrets create archon-chris-discord-bot-token \
    --data-file=- --project=YOUR_PROJECT_ID
```

Replace the placeholder values (`your-claude-oauth-token`, etc.) with your actual credentials, and `YOUR_PROJECT_ID` with your GCP project ID.

**What you should see** (for each):

```
Created secret [archon-chris-claude-oauth-token].
Created version [1] of the secret [archon-chris-claude-oauth-token].
```

To update a secret later:

```bash
echo -n "new-token-value" | \
  gcloud secrets versions add archon-chris-claude-oauth-token --data-file=-
```

## Step 4: Deploy with Terraform

```bash
./scripts/terraform-apply.sh
```

This runs `terraform plan`, shows what will be created, and asks for confirmation. Type `yes` to proceed.

**What you should see:**

```
→ Running terraform plan...

Terraform will perform the following actions:

  # module.archon_vm["chris"].google_compute_address.static will be created
  # module.archon_vm["chris"].google_compute_firewall.allow_https will be created
  # module.archon_vm["chris"].google_compute_instance.archon_vm will be created
  # module.archon_vm["chris"].google_service_account.archon_vm will be created
  # module.archon_vm["chris"].google_project_iam_member.secret_accessor will be created
  # module.archon_vm["chris"].tls_private_key.ssh will be created

Plan: 6 to add, 0 to change, 0 to destroy.

✓ Plan saved to tfplan

Apply this plan? (yes/no): yes

→ Applying Terraform plan...
Apply complete! Resources: 6 added, 0 changed, 0 destroyed.
✓ Terraform apply succeeded
```

Terraform creates a VM, a static IP, a firewall rule (HTTPS only), an SSH key pair, a service account, and grants it Secret Manager access. The VM's startup script automatically installs Docker, clones the repository, pulls secrets from Secret Manager, and starts Archon.

## Step 5: Configure OAuth2 Credentials on the VM

The VM is running but OAuth2 authentication is not yet configured. SSH to the VM and add the OAuth2 credentials to the `.env` file.

### Extract the SSH key

```bash
cd terraform && terraform output -raw ssh_private_keys | jq -r '.chris' > archon-chris.pem
chmod 600 archon-chris.pem
```

**What you should see:** A PEM-encoded private key file created in the `terraform/` directory.

> **Security:** Never commit `archon-chris.pem` to version control. This private key grants SSH access to your production VM. The `terraform/` directory is already in `.gitignore` to prevent accidental commits.

### Get the VM's IP address

```bash
cd terraform && terraform output instance_ips
```

**What you should see:**

```
{
  "chris" = "34.123.45.67"
}
```

Copy the IP address shown (e.g., `34.123.45.67`).

### SSH to the VM

```bash
ssh -i archon-chris.pem chris@34.123.45.67
```

Replace `34.123.45.67` with your actual IP and `chris` with your instance name.

### Update the .env file

Once connected to the VM:

```bash
cd ~/archon_core

# Generate a cookie secret
COOKIE_SECRET=$(openssl rand -base64 32)

# Add OAuth2 credentials to .env
cat >> .env <<EOF

# OAuth2 Proxy configuration
OAUTH2_PROXY_CLIENT_ID=your-client-id-from-step-1
OAUTH2_PROXY_CLIENT_SECRET=your-client-secret-from-step-1
OAUTH2_PROXY_COOKIE_SECRET=$COOKIE_SECRET
OAUTH_EMAIL=your-email@example.com
EOF
```

Replace:
- `your-client-id-from-step-1` with the Client ID from Step 1
- `your-client-secret-from-step-1` with the Client Secret from Step 1
- `your-email@example.com` with the email from `terraform.tfvars` `oauth_email`

### Restart containers

```bash
docker compose restart
```

**What you should see:** Containers restart successfully. Verify with `docker compose ps` - all containers should show "Up" status.

### Exit SSH

```bash
exit
```

You're back on your local machine. Continue to Step 6.

## Step 6: Get the VM's Static IP and Domain

```bash
cd terraform && terraform output sslip_domains
```

**What you should see:**

```
{
  "chris" = "34-123-45-67.sslip.io"
}
```

The domain uses [sslip.io](https://sslip.io), a free DNS service that maps `34-123-45-67.sslip.io` to `34.123.45.67`. Caddy uses this domain to automatically provision a TLS certificate from Let's Encrypt.

You can also get the raw IP:

```bash
cd terraform && terraform output instance_ips
```

**What you should see:**

```
{
  "chris" = "34.123.45.67"
}
```

Save this IP — you'll need it for GitHub Actions secrets and the OAuth redirect URI in the next step.

## Step 7: Configure GitHub Actions Deployment

GitHub Actions automates deployments: every push to `main` (or a manual trigger) SSHs into the VM, pulls the latest code, updates Docker images, and restarts containers.

### Set Up GitHub Repository Secrets

1. Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret** and add these two secrets:

| Secret name | Value | Where to get it |
|-------------|-------|-----------------|
| `DEPLOY_HOST` | The VM's static IP address (e.g., `34.123.45.67`) | `cd terraform && terraform output instance_ips` (Step 6) |
| `DEPLOY_SSH_KEY` | The SSH private key (PEM format) | Extract with the command below |

Extract the SSH private key from Terraform:

```bash
cd terraform && terraform output -raw ssh_private_keys | jq -r '.chris'
```

**What you should see:** A PEM-encoded private key starting with `-----BEGIN RSA PRIVATE KEY-----`. Copy the entire output (including the BEGIN/END lines) and paste it as the `DEPLOY_SSH_KEY` secret value.

> **Requires `jq`:** If you don't have `jq` installed, install it with `brew install jq` (macOS) or `sudo apt-get install jq` (Ubuntu/Debian).

### Update the OAuth Redirect URI

Now that you have the actual static IP, go back to the Google Cloud Console and update the redirect URI:

1. Go to [Google Cloud Console — Credentials](https://console.cloud.google.com/apis/credentials)
2. Click the **Archon OAuth2 Proxy** OAuth client you created in Step 1
3. Under **Authorized redirect URIs**, replace the placeholder with:
   ```
   https://34-123-45-67.sslip.io/oauth2/callback
   ```
   Replace `34-123-45-67` with your actual IP using **dashes instead of dots**.
4. Click **Save**

> **Dashes, not dots.** The sslip.io domain uses dashes between IP octets: `34-123-45-67.sslip.io`, not `34.123.45.67.sslip.io`. The redirect URI must match exactly.

### Trigger the First Deployment

Choose one of these options:

**Option A — Push to main:**

```bash
git commit --allow-empty -m "Trigger initial deploy" && git push origin main
```

**Option B — Manual trigger:**

1. Go to your GitHub repository → **Actions** tab
2. Click **Deploy** in the left sidebar
3. Click **Run workflow** → select `main` branch → click **Run workflow**

Monitor the deployment by clicking the running workflow in the Actions tab.

**What you should see:**

The workflow completes in ~2–3 minutes with a green checkmark. The final log line reads:

```
✓ Deployment complete - API is healthy
```

## Step 8: Verify Deployment and OAuth Access

Wait 2–3 minutes after the deployment completes for Caddy to provision the TLS certificate from Let's Encrypt.

Open your browser and go to:

```
https://34-123-45-67.sslip.io
```

Replace `34-123-45-67` with your actual IP (dashes, not dots).

### What happens on first access

1. **OAuth2 Proxy redirects you** to Google's sign-in page
2. **Sign in** with the email address you set as `oauth_email` in `terraform.tfvars`
3. **Grant permissions** when prompted (OAuth2 Proxy requests basic profile info)
4. **You're redirected back** to Archon's web UI

**What you should see:** The Archon web UI loads, showing the workflows page. You're authenticated and can start running workflows.

### Troubleshooting first access

| Symptom | Cause | Fix |
|---------|-------|-----|
| "403 Forbidden" or "not authorized" | Signed in with an email that doesn't match `oauth_email` | Sign in with the email specified in `terraform.tfvars`. Check on the VM with `docker compose logs oauth2-proxy`. |
| Browser certificate error | Caddy is still provisioning the TLS cert | Wait 2–3 minutes and refresh. Caddy needs time to complete the ACME challenge. |
| Connection refused / timeout | Containers not running yet | Check the GitHub Actions deploy logs. SSH to the VM and run `docker compose ps` to see container status. |
| Redirect URI mismatch error | OAuth redirect URI doesn't match the actual domain | Update the redirect URI in Google Cloud Console (Step 6) — it must use dashes and match exactly. |

## Day-to-Day Operations

### Deploying Updates

**Automatic deploys:** Every push to the `main` branch triggers the Deploy workflow. Merge a PR or push directly — GitHub Actions handles the rest.

**Manual deploys:** Go to your GitHub repository → **Actions** → **Deploy** → **Run workflow** → select `main` → **Run workflow**. This re-deploys the current `main` branch, which is useful for restarting containers or picking up config changes.

**What you should see:** The workflow completes in ~2–3 minutes with a green checkmark and `✓ Deployment complete - API is healthy` in the logs.

### Checking Logs

**GitHub Actions logs:** Go to **Actions** tab → click a deploy run → expand the **Deploy to GCP VM via SSH** step to see the full deployment output.

**Container logs on the VM:** SSH in (see below) and run:

```bash
cd ~/archon_core && docker compose logs -f
```

Press `Ctrl+C` to stop streaming. Remove `-f` to print existing logs and exit.

**VM startup log** (from initial provisioning):

```bash
sudo cat /var/log/archon-startup.log
```

### SSH Access

Extract the SSH key (one-time setup):

```bash
cd terraform && terraform output -raw ssh_private_keys | jq -r '.chris' > archon-chris.pem
chmod 600 archon-chris.pem
```

**What you should see:** A PEM-encoded private key file created in the `terraform/` directory.

> **Security:** Never commit `archon-chris.pem` to version control. This private key grants SSH access to your production VM. The `terraform/` directory is already in `.gitignore` to prevent accidental commits.

Connect to the VM:

```bash
ssh -i archon-chris.pem chris@34.123.45.67
```

Replace `chris` with your instance name (the map key from `terraform.tfvars`) and `34.123.45.67` with your VM's static IP.

### Restarting Services

**Via GitHub Actions** (recommended): Trigger a manual deploy — it pulls latest code and restarts all containers.

**Via SSH:**

```bash
cd ~/archon_core && docker compose restart
```

For a full restart (stops and recreates containers):

```bash
cd ~/archon_core && docker compose down && docker compose up -d
```

**What you should see:** Containers transition to healthy status within 15–30 seconds. Verify with `docker compose ps`.

### Checking Service Health

**From outside the VM:**

```bash
curl -sf https://34-123-45-67.sslip.io/api/health
```

This goes through OAuth2 Proxy — if you're not authenticated, you'll get a redirect. For an unauthenticated check, SSH in.

**From the VM (via SSH):**

```bash
curl -sf http://localhost:3000/api/health
```

**What you should see:**

```json
{"status":"ok"}
```

## Adding More Instances

Edit `terraform/terraform.tfvars` and add another entry to the map:

```hcl
archon_instances = {
  chris = {
    secrets_map = {
      claude_oauth_token = "archon-chris-claude-oauth-token"
      github_token       = "archon-chris-github-token"
      discord_bot_token  = "archon-chris-discord-bot-token"
    }
  }
  alice = {
    secrets_map = {
      claude_oauth_token = "archon-alice-claude-oauth-token"
      github_token       = "archon-alice-github-token"
      discord_bot_token  = "archon-alice-discord-bot-token"
    }
  }
}
```

Create the new secrets in Secret Manager (Step 3), then run `./scripts/terraform-apply.sh` again. Each instance gets its own VM, static IP, and SSH key.

## Destroying Resources

To tear down all Terraform-managed resources:

```bash
./scripts/terraform-destroy.sh
```

This previews what will be deleted and requires you to type `yes` to confirm.

**Cost note:** Static IPs are free while attached to a running VM but cost ~$8/month when the VM is stopped but the IP is reserved. Destroying releases the IP.

## Troubleshooting

### Startup script fails — container not running

SSH to the VM and check the startup log:

```bash
sudo cat /var/log/archon-startup.log
```

Common causes:

- **Secret Manager permission denied** — the service account doesn't have `secretmanager.secretAccessor` role, or the secret name in tfvars doesn't match what was created
- **Docker install failed** — network issue during apt-get; re-run the startup script manually or recreate the VM
- **Git clone failed** — the repository URL is wrong or the VM can't reach GitHub

### "Error 403: Required 'compute.instances.create' permission"

Your GCP user account needs the Compute Admin role on the project:

```bash
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="user:your-email@example.com" \
  --role="roles/compute.admin"
```

### "Quota exceeded for resource 'EXTERNAL_IP_ADDRESSES'"

Request a quota increase in the GCP Console under **IAM & Admin > Quotas**.

### Terraform state is out of sync

If resources were modified outside Terraform:

```bash
cd terraform && terraform refresh
```

### GitHub Actions deploy fails

Check the workflow run logs in **Actions** tab. Common causes:

- **SSH connection failed** — verify `DEPLOY_HOST` secret matches `terraform output instance_ips` and `DEPLOY_SSH_KEY` contains the full PEM key including BEGIN/END lines
- **"Permission denied (publickey)"** — the SSH key doesn't match; re-extract with `terraform output -raw ssh_private_keys | jq -r '.chris'` and update the GitHub secret
- **Docker pull failed on VM** — the VM may not have internet access; check firewall rules with `gcloud compute firewall-rules list --project=YOUR_PROJECT_ID`

### OAuth2 Proxy returns "Internal Server Error"

SSH to the VM and check the OAuth2 Proxy logs:

```bash
cd ~/archon_core && docker compose logs oauth2-proxy
```

Common causes:

- **Missing or invalid Client ID/Secret** — verify the OAuth2 credentials in the `.env` file on the VM match what's in Google Cloud Console
- **Cookie secret not set** — ensure `OAUTH2_PROXY_COOKIE_SECRET` is set in `.env` on the VM

### Terraform heredoc or Docker permission errors

See [INFRASTRUCTURE-ISSUES.md](INFRASTRUCTURE-ISSUES.md) for documented solutions to:

- **Terraform heredoc escaping** — `${VAR}` vs `$VAR` in startup scripts
- **Docker config permissions** — `~/.docker/config.json` owned by root
- **Startup script timing** — containers need stabilization time after `docker compose up -d`

These are operational gotchas that have known workarounds documented in detail.

## Something went wrong?

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for additional common errors and fixes not specific to GCP deployment.
