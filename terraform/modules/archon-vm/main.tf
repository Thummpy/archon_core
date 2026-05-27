terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0"
    }
  }
}

# ---------------------------------------------------------------------------
# SSH Key
# ---------------------------------------------------------------------------

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# ---------------------------------------------------------------------------
# Service Account (least-privilege: Secret Manager read-only)
# ---------------------------------------------------------------------------

resource "google_service_account" "archon_vm" {
  account_id   = "${var.instance_name}-sa"
  display_name = "Archon VM service account for ${var.instance_name}"
  project      = var.project_id
}

resource "google_project_iam_member" "secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.archon_vm.email}"
}

# ---------------------------------------------------------------------------
# Networking
# ---------------------------------------------------------------------------

resource "google_compute_address" "static" {
  name         = "${var.instance_name}-ip"
  region       = var.region
  address_type = "EXTERNAL"
  project      = var.project_id
}

resource "google_compute_firewall" "allow_https" {
  name    = "${var.instance_name}-allow-https"
  network = "default"
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges          = ["0.0.0.0/0"]
  target_service_accounts = [google_service_account.archon_vm.email]
}

# ---------------------------------------------------------------------------
# Startup Script
# ---------------------------------------------------------------------------

locals {
  user_home = "/home/${var.ssh_username}"

  startup_script = <<-SCRIPT
    #!/bin/bash
    set -euo pipefail
    exec > /var/log/archon-startup.log 2>&1

    USERNAME="${var.ssh_username}"
    USER_HOME="${local.user_home}"

    echo "→ Updating package lists..."
    apt-get update

    echo "→ Installing prerequisites..."
    apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release jq

    echo "→ Adding Docker GPG key..."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
      | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

    echo "→ Configuring Docker repository..."
    ARCH=$$(dpkg --print-architecture)
    CODENAME=$$(lsb_release -cs)
    echo "deb [arch=$$ARCH signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $$CODENAME stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    echo "→ Installing Docker Engine..."
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

    echo "→ Starting Docker..."
    systemctl start docker
    systemctl enable docker

    echo "→ Adding $$USERNAME to docker group..."
    usermod -aG docker "$$USERNAME"

    echo "→ Retrieving secrets from Secret Manager..."

    echo "  → Fetching claude_oauth_token..."
    if ! CLAUDE_CODE_OAUTH_TOKEN=$$(gcloud secrets versions access latest --secret="${var.secrets_map.claude_oauth_token}" 2>&1); then
      echo "✗ Failed to retrieve secret: ${var.secrets_map.claude_oauth_token}" >&2
      echo "  Error: $$CLAUDE_CODE_OAUTH_TOKEN" >&2
      echo "  Verify: secret exists, service account has secretmanager.secretAccessor, API enabled" >&2
      exit 1
    fi

    echo "  → Fetching github_token..."
    if ! GITHUB_TOKEN=$$(gcloud secrets versions access latest --secret="${var.secrets_map.github_token}" 2>&1); then
      echo "✗ Failed to retrieve secret: ${var.secrets_map.github_token}" >&2
      echo "  Error: $$GITHUB_TOKEN" >&2
      exit 1
    fi

    echo "  → Fetching discord_bot_token..."
    if ! DISCORD_BOT_TOKEN=$$(gcloud secrets versions access latest --secret="${var.secrets_map.discord_bot_token}" 2>&1); then
      echo "✗ Failed to retrieve secret: ${var.secrets_map.discord_bot_token}" >&2
      echo "  Error: $$DISCORD_BOT_TOKEN" >&2
      exit 1
    fi

    OAUTH2_CLIENT_ID=""
    OAUTH2_CLIENT_SECRET=""
    %{ if var.secrets_map.oauth2_client_id != "" ~}
    echo "  → Fetching oauth2_client_id..."
    if ! OAUTH2_CLIENT_ID=$$(gcloud secrets versions access latest --secret="${var.secrets_map.oauth2_client_id}" 2>&1); then
      echo "⚠ Failed to retrieve oauth2_client_id (OAuth2 Proxy will not work until configured)" >&2
      OAUTH2_CLIENT_ID=""
    fi

    echo "  → Fetching oauth2_client_secret..."
    if ! OAUTH2_CLIENT_SECRET=$$(gcloud secrets versions access latest --secret="${var.secrets_map.oauth2_client_secret}" 2>&1); then
      echo "⚠ Failed to retrieve oauth2_client_secret (OAuth2 Proxy will not work until configured)" >&2
      OAUTH2_CLIENT_SECRET=""
    fi
    %{ endif ~}

    echo "✓ All secrets retrieved successfully"

    echo "→ Cloning repository..."
    sudo -u "$$USERNAME" git clone ${var.github_repo_url} "$$USER_HOME/archon_core"

    echo "→ Resolving sslip.io domain..."
    EXTERNAL_IP=$$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip -H "Metadata-Flavor: Google")
    ARCHON_DOMAIN=$$(echo $$EXTERNAL_IP | tr '.' '-').sslip.io
    echo "  Domain: $$ARCHON_DOMAIN"

    echo "→ Generating OAuth2 cookie secret..."
    OAUTH2_COOKIE_SECRET=$$(openssl rand -base64 32)

    echo "→ Writing .env file..."
    cat > "$$USER_HOME/archon_core/.env" <<EOF
CLAUDE_CODE_OAUTH_TOKEN=$$CLAUDE_CODE_OAUTH_TOKEN
GITHUB_TOKEN=$$GITHUB_TOKEN
DISCORD_BOT_TOKEN=$$DISCORD_BOT_TOKEN
ARCHON_DOMAIN=$$ARCHON_DOMAIN
PORT=3000
OAUTH2_PROXY_CLIENT_ID=$$OAUTH2_CLIENT_ID
OAUTH2_PROXY_CLIENT_SECRET=$$OAUTH2_CLIENT_SECRET
OAUTH2_PROXY_COOKIE_SECRET=$$OAUTH2_COOKIE_SECRET
OAUTH_EMAIL=${var.oauth_email}
EOF

    echo "→ Creating data directory..."
    mkdir -p "$$USER_HOME/archon-data"
    chown -R "$$USERNAME:$$USERNAME" "$$USER_HOME/archon_core" "$$USER_HOME/archon-data"

    echo "→ Building and starting Archon..."
    cd "$$USER_HOME/archon_core"
    export HOME="$$USER_HOME"
    if ! docker compose up -d --build; then
      echo "✗ docker compose up failed" >&2
      docker compose logs --tail=30 >&2
      exit 1
    fi

    echo "→ Waiting for containers to stabilize (30s)..."
    sleep 30

    echo "→ Verifying containers..."
    docker compose ps
    if ! docker compose ps --format json | grep -q archon-app; then
      echo "✗ archon-app not running" >&2
      docker compose logs --tail=50 >&2
      exit 1
    fi

    echo "✓ Archon startup complete"
    echo "✓ Access at: https://$$ARCHON_DOMAIN"
    touch /var/log/archon-startup-complete
  SCRIPT
}

# ---------------------------------------------------------------------------
# Compute Instance
# ---------------------------------------------------------------------------

resource "google_compute_instance" "archon_vm" {
  name                      = var.instance_name
  machine_type              = var.machine_type
  zone                      = var.zone
  project                   = var.project_id
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "projects/${var.image_project}/global/images/family/${var.image_family}"
      size  = var.disk_size_gb
      type  = "pd-standard"
    }
  }

  network_interface {
    network = "default"

    access_config {
      nat_ip = google_compute_address.static.address
    }
  }

  service_account {
    email  = google_service_account.archon_vm.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    ssh-keys       = "${var.ssh_username}:${tls_private_key.ssh.public_key_openssh}"
    enable-oslogin = "FALSE"
  }

  metadata_startup_script = local.startup_script
}
