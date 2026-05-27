# GCP Deployment — Provisioning Archon VMs

How to create secrets in GCP, deploy VMs with Terraform, and verify Archon is running.

**Prerequisite:** Complete [TERRAFORM-SETUP.md](TERRAFORM-SETUP.md) first.

## What you need before starting

- Terraform initialized (`./scripts/terraform-init.sh` ran successfully)
- `terraform/terraform.tfvars` populated with your GCP project and instance config
- Your secret values ready: Claude OAuth token, GitHub token, Discord bot token

## Step 1: Enable GCP APIs

Terraform needs Compute Engine, Secret Manager, and IAM APIs enabled:

```bash
gcloud services enable compute.googleapis.com --project=YOUR_PROJECT_ID
gcloud services enable secretmanager.googleapis.com --project=YOUR_PROJECT_ID
gcloud services enable iam.googleapis.com --project=YOUR_PROJECT_ID
```

**What you should see:**

```
Operation "operations/..." finished successfully.
```

## Step 2: Create Secrets in Secret Manager

Create a secret for each credential. The secret **names** must match what you put in `terraform.tfvars`.

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

## Step 3: Deploy with Terraform

```bash
./scripts/terraform-apply.sh
```

This runs `terraform plan`, shows what will be created, and asks for confirmation.

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

## Step 4: Get the VM's IP Address

```bash
cd terraform && terraform output instance_ips
```

**What you should see:**

```
{
  "chris" = "34.xxx.xxx.xxx"
}
```

## Step 5: Save the SSH Private Key

The SSH key is marked sensitive. Extract it for secure storage:

```bash
cd terraform && terraform output -raw ssh_private_keys | jq -r '.chris' > archon-chris.pem
chmod 600 archon-chris.pem
```

Store this key securely (e.g., as a GitHub Actions secret). Do not commit it to version control.

## Step 6: SSH to the VM

Wait 3-5 minutes after `terraform apply` for the startup script to finish installing Docker and starting Archon.

```bash
ssh -i archon-chris.pem chris@caldwell.ws@EXTERNAL_IP
```

Replace `EXTERNAL_IP` with the IP from Step 4.

## Step 7: Verify Archon Is Running

On the VM:

```bash
sudo docker ps
```

**What you should see:**

```
CONTAINER ID   IMAGE                              STATUS         PORTS
abc123         ghcr.io/coleam00/archon:0.3.12     Up 2 minutes   0.0.0.0:3000->3000/tcp
```

Check the startup log if the container isn't running:

```bash
sudo cat /var/log/archon-startup.log
```

## Step 8: Access Archon

Archon runs on port 3000 inside the VM. The firewall only opens port 443, so you'll need to use an SSH tunnel to access the web UI:

```bash
ssh -i archon-chris.pem -L 3000:localhost:3000 chris@caldwell.ws@EXTERNAL_IP
```

Then open **http://localhost:3000** in your browser.

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

Create the new secrets in Secret Manager, then run `./scripts/terraform-apply.sh` again.

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
