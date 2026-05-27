terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

module "archon_vm" {
  source   = "./modules/archon-vm"
  for_each = var.archon_instances

  project_id    = var.gcp_project_id
  region        = var.gcp_region
  zone          = var.gcp_zone
  instance_name = "archon-${each.key}"
  oauth_email   = var.oauth_email
  ssh_username  = each.key
  secrets_map   = each.value.secrets_map
}
