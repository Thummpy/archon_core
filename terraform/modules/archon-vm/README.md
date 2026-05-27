# archon-vm Module

Provisions a GCP Compute Engine VM configured to run Archon in Docker.

## What It Creates

- **Compute Instance** — e2-medium (configurable) running Ubuntu 22.04 LTS
- **Static External IP** — persistent address attached to the VM
- **Firewall Rule** — allows only port 443 inbound from any source
- **Service Account** — least-privilege, with Secret Manager read-only access
- **SSH Keypair** — Terraform-generated RSA 4096-bit key

The VM's startup script installs Docker, retrieves secrets from GCP Secret Manager, clones the repository, and runs `docker compose up -d`.

## Prerequisites

Enable these GCP APIs in your project before use:

```bash
gcloud services enable compute.googleapis.com
gcloud services enable secretmanager.googleapis.com
gcloud services enable iam.googleapis.com
```

## Usage

```hcl
module "archon_vm_chris" {
  source = "./modules/archon-vm"

  project_id    = "my-gcp-project"
  region        = "us-central1"
  zone          = "us-central1-a"
  instance_name = "archon-chris"
  oauth_email   = "chris@caldwell.ws"

  secrets_map = {
    claude_oauth_token = "archon-chris-claude-oauth-token"
    github_token       = "archon-chris-github-token"
    discord_bot_token  = "archon-chris-discord-bot-token"
  }
}
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `project_id` | string | — | GCP project ID |
| `region` | string | `us-central1` | GCP region for regional resources |
| `zone` | string | `us-central1-a` | GCP zone for the compute instance |
| `instance_name` | string | — | Name for the VM and derived resources |
| `machine_type` | string | `e2-medium` | GCP machine type |
| `image_family` | string | `ubuntu-2204-lts` | OS image family |
| `image_project` | string | `ubuntu-os-cloud` | GCP project hosting the image |
| `oauth_email` | string | — | Email for SSH key user and OAuth whitelist |
| `github_repo_url` | string | `https://github.com/Thummpy/archon_core.git` | Repo to clone on the VM |
| `archon_version` | string | `0.3.12` | Archon Docker image tag |
| `secrets_map` | object | — | Secret Manager secret names (sensitive) |

## Outputs

| Name | Sensitive | Description |
|------|-----------|-------------|
| `external_ip` | No | Static IP address of the VM |
| `instance_name` | No | Name of the compute instance |
| `instance_id` | No | GCP resource ID |
| `ssh_private_key` | **Yes** | PEM-encoded private key for SSH |
| `ssh_public_key` | No | OpenSSH public key deployed to VM |

## Security Notes

- The VM uses a **dedicated service account** with only `roles/secretmanager.secretAccessor` — not the default Compute Engine SA.
- The firewall rule targets the service account, not instance tags (tags can be modified by anyone with instance-edit IAM; SA assignment requires IAM admin).
- The SSH private key is stored in Terraform state. Secure your state file and mark the output as sensitive.
- Secrets never appear in Terraform configuration — only Secret Manager resource names are referenced.
