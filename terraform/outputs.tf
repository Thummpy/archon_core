output "instance_ips" {
  description = "Map of instance name to external IP address"
  value       = { for k, v in module.archon_vm : k => v.external_ip }
}

output "instance_ids" {
  description = "Map of instance name to GCP instance ID"
  value       = { for k, v in module.archon_vm : k => v.instance_id }
}

output "ssh_private_keys" {
  description = "Map of instance name to PEM-encoded SSH private key"
  value       = { for k, v in module.archon_vm : k => v.ssh_private_key }
  sensitive   = true
}

output "ssh_public_keys" {
  description = "Map of instance name to OpenSSH public key"
  value       = { for k, v in module.archon_vm : k => v.ssh_public_key }
}

output "sslip_domains" {
  description = "Map of instance name to sslip.io HTTPS domain"
  value       = { for k, v in module.archon_vm : k => v.sslip_domain }
}
