# Debian VM Outputs
output "vm_id" {
  description = "Debian VM ID"
  value       = module.debian_vm.id
}

output "vm_name" {
  description = "Debian VM name"
  value       = module.debian_vm.name
}

output "vm_ip" {
  description = "Debian VM IP address"
  value       = module.debian_vm.ip
}
