# Terraform Setup — First-Time Configuration

How to install Terraform and configure GCP credentials for cloud deployment.

## What you need before starting

- A **GCP project** with billing enabled
- **Google Cloud SDK** (`gcloud`) installed ([install guide](https://cloud.google.com/sdk/docs/install))
- **Terraform >= 1.5** installed ([install guide](https://developer.hashicorp.com/terraform/install))
- A terminal with `bash`

## Step 1: Install Terraform

Download and install Terraform for your platform.

**macOS (Homebrew):**

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

**Ubuntu/Debian:**

```bash
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update && sudo apt-get install terraform
```

**Verify:**

```bash
terraform -version
```

**What you should see:**

```
Terraform v1.x.x
```

## Step 2: Install Google Cloud SDK

If you don't already have `gcloud`, install it from [cloud.google.com/sdk/docs/install](https://cloud.google.com/sdk/docs/install).

**Verify:**

```bash
gcloud --version
```

## Step 3: Authenticate with GCP

Terraform uses application-default credentials. This is a local credential that Terraform reads automatically — no service account JSON files needed.

```bash
gcloud auth application-default login
```

A browser window opens. Sign in with the Google account that has access to your GCP project.

**What you should see:**

```
Credentials saved to file: [/home/you/.config/gcloud/application_default_credentials.json]
```

## Step 4: Create terraform.tfvars

Copy the example file and fill in your values:

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
```

Edit `terraform/terraform.tfvars`:

```hcl
gcp_project_id = "your-gcp-project-id"
oauth_email    = "chris@caldwell.ws"

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

The `secrets_map` values are the **names** of secrets in GCP Secret Manager, not the secret values themselves. You'll create these secrets in [GCP-DEPLOYMENT.md](GCP-DEPLOYMENT.md).

## Step 5: Initialize Terraform

```bash
./scripts/terraform-init.sh
```

**What you should see:**

```
✓ GCP application-default credentials configured
→ Initializing Terraform in /path/to/terraform...
Terraform has been successfully initialized!
✓ Terraform initialized successfully
→ Validating Terraform configuration...
Success! The configuration is valid.
✓ Terraform configuration is valid
```

This downloads the Google Cloud and TLS providers into `terraform/.terraform/` (gitignored).

## Next Step

Proceed to [GCP-DEPLOYMENT.md](GCP-DEPLOYMENT.md) to create secrets and deploy.

## Troubleshooting

### "GCP application-default credentials not configured"

Run `gcloud auth application-default login` and sign in with a Google account that has access to the target GCP project.

### "Terraform init failed"

Check your internet connection. Terraform needs to download providers from `registry.terraform.io`. If you're behind a corporate proxy, configure `HTTPS_PROXY`.

### "The configuration is not valid"

Run `terraform -chdir=terraform validate` for the full error. Common causes: typo in `terraform.tfvars`, missing required variable.
