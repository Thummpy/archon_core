variable "project_id" {
  description = "GCP project ID where resources will be created"
  type        = string
}

variable "region" {
  description = "GCP region for regional resources (static IP)"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone for the compute instance"
  type        = string
  default     = "us-central1-a"
}

variable "instance_name" {
  description = "Name for the compute instance and derived resource names"
  type        = string
}

variable "machine_type" {
  description = "GCP machine type for the compute instance"
  type        = string
  default     = "e2-medium"
}

variable "image_family" {
  description = "OS image family for the boot disk"
  type        = string
  default     = "ubuntu-2204-lts"
}

variable "image_project" {
  description = "GCP project hosting the OS image family"
  type        = string
  default     = "ubuntu-os-cloud"
}

variable "oauth_email" {
  description = "Email address for OAuth whitelist"
  type        = string
}

variable "ssh_username" {
  description = "SSH username for the compute instance (alphanumeric, no special characters)"
  type        = string
  default     = "archon"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*$", var.ssh_username))
    error_message = "SSH username must start with a letter and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "github_repo_url" {
  description = "HTTPS URL of the archon_core repository to clone on the VM"
  type        = string
  default     = "https://github.com/Thummpy/archon_core.git"
}

variable "disk_size_gb" {
  description = "Boot disk size in GB for the compute instance"
  type        = number
  default     = 30

  validation {
    condition     = var.disk_size_gb >= 10 && var.disk_size_gb <= 10000
    error_message = "Disk size must be between 10 and 10000 GB."
  }
}

variable "secrets_map" {
  description = "GCP Secret Manager secret names for per-instance credentials"
  type = object({
    claude_oauth_token   = string
    github_token         = string
    discord_bot_token    = string
    oauth2_client_id     = optional(string, "")
    oauth2_client_secret = optional(string, "")
  })
  sensitive = true
}
