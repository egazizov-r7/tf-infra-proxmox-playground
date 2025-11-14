# Windows Tiny10 VM Outputs
output "vm_id" {
  description = "Windows Tiny10 VM ID"
  value       = module.windows_tiny10_vm.id
}

output "vm_name" {
  description = "Windows Tiny10 VM name"
  value       = module.windows_tiny10_vm.name
}

output "vm_ip" {
  description = "Windows Tiny10 VM IP address"
  value       = module.windows_tiny10_vm.ip
}
