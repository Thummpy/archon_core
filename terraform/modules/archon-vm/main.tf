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
  startup_script = <<-SCRIPT
    #!/bin/bash
    set -euo pipefail
    exec > /var/log/archon-startup.log 2>&1

    echo "→ Updating package lists..."
    apt-get update

    echo "→ Installing prerequisites..."
    apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

    echo "→ Adding Docker GPG key..."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
      | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

    echo "→ Configuring Docker repository..."
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
      https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
      | tee /etc/apt/sources.list.d/docker.list > /dev/null

    echo "→ Installing Docker Engine..."
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

    echo "→ Starting Docker..."
    systemctl start docker
    systemctl enable docker

    echo "→ Retrieving secrets from Secret Manager..."
    CLAUDE_CODE_OAUTH_TOKEN=$(gcloud secrets versions access latest --secret="${var.secrets_map.claude_oauth_token}")
    GITHUB_TOKEN=$(gcloud secrets versions access latest --secret="${var.secrets_map.github_token}")
    DISCORD_BOT_TOKEN=$(gcloud secrets versions access latest --secret="${var.secrets_map.discord_bot_token}")

    echo "→ Cloning repository..."
    mkdir -p /opt/archon
    cd /opt/archon
    git clone ${var.github_repo_url} .

    echo "→ Writing .env file..."
    cat > .env <<EOF
    CLAUDE_CODE_OAUTH_TOKEN=$CLAUDE_CODE_OAUTH_TOKEN
    GITHUB_TOKEN=$GITHUB_TOKEN
    DISCORD_BOT_TOKEN=$DISCORD_BOT_TOKEN
    PORT=3000
    EOF

    echo "→ Creating data directory..."
    mkdir -p /opt/archon-data
    export HOME=/opt

    echo "→ Starting Archon..."
    docker compose up -d

    echo "✓ Archon startup complete"
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
      size  = 30
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
    ssh-keys       = "${var.oauth_email}:${tls_private_key.ssh.public_key_openssh}"
    enable-oslogin = "FALSE"
  }

  metadata_startup_script = local.startup_script
}
