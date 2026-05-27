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
  description = "Email address for SSH key user and OAuth whitelist"
  type        = string
}

variable "github_repo_url" {
  description = "HTTPS URL of the archon_core repository to clone on the VM"
  type        = string
  default     = "https://github.com/Thummpy/archon_core.git"
}

variable "archon_version" {
  description = "Archon Docker image tag to deploy"
  type        = string
  default     = "0.3.12"
}

variable "secrets_map" {
  description = "GCP Secret Manager secret names for per-instance credentials"
  type = object({
    claude_oauth_token = string
    github_token       = string
    discord_bot_token  = string
  })
  sensitive = true
}
