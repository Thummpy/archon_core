# Deploy Archon to GCP — Complete Walkthrough

One guide covering everything: prerequisites, secrets, Terraform, first deploy, and day-to-day ops.

For the individual reference docs, see [TERRAFORM-SETUP.md](TERRAFORM-SETUP.md), [GCP-DEPLOYMENT.md](GCP-DEPLOYMENT.md), and [DEPLOYMENT.md](DEPLOYMENT.md).

## What you need before starting

- A Google account with GCP billing enabled
- A terminal with `bash`
- ~30 minutes for first-time setup

## Step 1: Install Tools

**Google Cloud SDK** — [cloud.google.com/sdk/docs/install](https://cloud.google.com/sdk/docs/install)

```bash
gcloud --version
```

**Terraform** — [developer.hashicorp.com/terraform/install](https://developer.hashicorp.com/terraform/install)

```bash
# macOS
brew tap hashicorp/tap && brew install hashicorp/tap/terraform

# Ubuntu/Debian
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update && sudo apt-get install terraform
```

Verify both:

```bash
gcloud --version && terraform -version
```

## Step 2: Create GCP Project

If you don't have one yet, create a project at [console.cloud.google.com](https://console.cloud.google.com) → **New Project**. Note the **project ID** (the slug, not the display name).

Enable the required APIs:

```bash
gcloud services enable compute.googleapis.com --project=YOUR_PROJECT_ID
gcloud services enable secretmanager.googleapis.com --project=YOUR_PROJECT_ID
gcloud services enable iam.googleapis.com --project=YOUR_PROJECT_ID
```

Authenticate Terraform:

```bash
gcloud auth application-default login
```

A browser opens — sign in with the Google account that owns the project.

## Step 3: Create Google OAuth Client

This is for the login page that protects Archon's web UI.

1. Go to [console.cloud.google.com/apis/credentials](https://console.cloud.google.com/apis/credentials?project=YOUR_PROJECT_ID)
2. **Configure consent screen** (if not done):
   - User Type: **External**
   - App name: "Archon" (anything)
   - User support email: your email
   - Scopes: click **Add or Remove Scopes** → check `email` and `profile` → Save
   - Test users: **Add** your email (only listed users can log in while app is in "Testing" status — this is what you want)
   - Save and Continue through to the end
3. Back on Credentials page → **+ Create Credentials** → **OAuth client ID**
   - Application type: **Web application**
   - Name: "Archon OAuth" (anything)
   - Authorized redirect URIs: leave empty for now (you'll add it after Step 6)
   - Click **Create**
4. Copy the **Client ID** and **Client Secret** — you'll need them in Step 5

## Step 4: Get Your Other Tokens

**Claude OAuth Token** — needed for Claude Code to work:

```bash
./scripts/setup-oauth.sh
```

This opens a browser. Log into your Claude Max account, authorize, and copy the token (starts with `sk-ant-oat-...`).

**GitHub Fine-Grained PAT** — needed for cloning private repos:

1. Go to [github.com/settings/tokens?type=beta](https://github.com/settings/tokens?type=beta)
2. **Generate new token**
3. Scope it to your repos with **Contents: Read and write**
4. Copy the token

## Step 5: Store Secrets in GCP Secret Manager

Create a secret for each credential. Replace the placeholder values with your actual tokens:

```bash
PROJECT=YOUR_PROJECT_ID

echo -n "sk-ant-oat-YOUR-TOKEN" | \
  gcloud secrets create archon-chris-claude-oauth-token --data-file=- --project=$PROJECT

echo -n "github_pat_YOUR-TOKEN" | \
  gcloud secrets create archon-chris-github-token --data-file=- --project=$PROJECT

echo -n "placeholder" | \
  gcloud secrets create archon-chris-discord-bot-token --data-file=- --project=$PROJECT
```

The Discord token is a placeholder for now — update it later when you set up the Discord bot.

## Step 6: Deploy with Terraform

Configure your variables:

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
```

Edit `terraform/terraform.tfvars`:

```hcl
gcp_project_id = "YOUR_PROJECT_ID"
oauth_email    = "your-email@example.com"

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

Initialize and deploy:

```bash
./scripts/terraform-init.sh
./scripts/terraform-apply.sh
```

Terraform shows what it will create and asks for confirmation. Type `yes`.

After it finishes, get your domain:

```bash
cd terraform && terraform output sslip_domains
```

**What you should see:**

```
{
  "chris" = "34-xxx-xxx-xxx.sslip.io"
}
```

Save the SSH key:

```bash
terraform output -raw ssh_private_keys | jq -r '.chris' > archon-chris.pem
chmod 600 archon-chris.pem
```

## Step 7: Update OAuth Redirect URI

Now that you have the domain, go back to the GCP Console:

1. [console.cloud.google.com/apis/credentials](https://console.cloud.google.com/apis/credentials)
2. Click your OAuth client ID
3. Under **Authorized redirect URIs**, add: `https://34-xxx-xxx-xxx.sslip.io/oauth2/callback` (use your actual domain)
4. Save

## Step 8: Configure the VM

SSH into the VM:

```bash
ssh -i archon-chris.pem chris@EXTERNAL_IP
```

Create the `.env` file:

```bash
cd ~/archon_core
cat > .env << 'EOF'
CLAUDE_CODE_OAUTH_TOKEN=sk-ant-oat-YOUR-TOKEN
GITHUB_TOKEN=github_pat_YOUR-TOKEN
OAUTH2_PROXY_CLIENT_ID=YOUR-OAUTH-CLIENT-ID
OAUTH2_PROXY_CLIENT_SECRET=YOUR-OAUTH-CLIENT-SECRET
OAUTH2_PROXY_COOKIE_SECRET=GENERATE-WITH-OPENSSL
OAUTH_EMAIL=your-email@example.com
ARCHON_DOMAIN=34-xxx-xxx-xxx.sslip.io
EOF
```

Generate the cookie secret:

```bash
openssl rand -base64 32
```

Paste the output as the `OAUTH2_PROXY_COOKIE_SECRET` value.

Start the services:

```bash
docker compose pull && docker compose up -d
```

## Step 9: Configure GitHub Actions Deploy

So future pushes to `main` auto-deploy:

1. GitHub repo → **Settings** → **Secrets and variables** → **Actions**
2. Add **DEPLOY_SSH_KEY**: paste the contents of `archon-chris.pem`
3. Add **DEPLOY_HOST**: the raw IP address (dots, not dashes)

Test it: push anything to `main` and watch the **Actions** tab.

## Step 10: Verify

Wait 2-3 minutes for the TLS certificate, then open:

```
https://34-xxx-xxx-xxx.sslip.io
```

You'll see a Google login page. Sign in with the email you whitelisted. After login, you're in the Archon web UI.

## Day-to-Day Operations

**Deploy:** Push to `main`. GitHub Actions handles the rest.

**Manual deploy:** Actions tab → Deploy workflow → Run workflow.

**Check logs:**

```bash
ssh -i archon-chris.pem chris@EXTERNAL_IP
cd ~/archon_core && docker compose logs -f
```

**Restart:**

```bash
ssh -i archon-chris.pem chris@EXTERNAL_IP
cd ~/archon_core && docker compose restart
```

**Update a secret:** Change the value in `.env` on the VM, then `docker compose up -d`.

**Tear down everything:**

```bash
./scripts/terraform-destroy.sh
```

## Something went wrong?

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues. For Terraform-specific problems, see [GCP-DEPLOYMENT.md](GCP-DEPLOYMENT.md#troubleshooting).
