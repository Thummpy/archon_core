output "external_ip" {
  description = "Static external IP address assigned to the VM"
  value       = google_compute_address.static.address
}

output "instance_name" {
  description = "Name of the created compute instance"
  value       = google_compute_instance.archon_vm.name
}

output "instance_id" {
  description = "GCP resource ID of the compute instance"
  value       = google_compute_instance.archon_vm.instance_id
}

output "ssh_private_key" {
  description = "PEM-encoded private key for SSH access (store securely)"
  value       = tls_private_key.ssh.private_key_pem
  sensitive   = true
}

output "ssh_public_key" {
  description = "OpenSSH-formatted public key deployed to the VM"
  value       = tls_private_key.ssh.public_key_openssh
}
