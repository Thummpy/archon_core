variable "gcp_project_id" {
  description = "GCP project ID where all resources will be created"
  type        = string
}

variable "gcp_region" {
  description = "Default GCP region for regional resources"
  type        = string
  default     = "us-central1"
}

variable "gcp_zone" {
  description = "Default GCP zone for zonal resources"
  type        = string
  default     = "us-central1-a"
}

variable "oauth_email" {
  description = "Email address for OAuth whitelist and SSH access"
  type        = string
}

variable "archon_instances" {
  description = "Map of instance configurations — add entries to provision more VMs"
  type = map(object({
    secrets_map = object({
      claude_oauth_token = string
      github_token       = string
      discord_bot_token  = string
    })
  }))
  default = {
    chris = {
      secrets_map = {
        claude_oauth_token = "archon-chris-claude-oauth-token"
        github_token       = "archon-chris-github-token"
        discord_bot_token  = "archon-chris-discord-bot-token"
      }
    }
  }
  sensitive = true
}
