# Nginx Proxy Manager Container Outputs
output "container_id" {
  description = "Nginx Proxy Manager Container ID"
  value       = module.nginx_proxy_manager.id
}

output "container_hostname" {
  description = "Nginx Proxy Manager Container hostname"
  value       = module.nginx_proxy_manager.hostname
}

output "container_ip" {
  description = "Nginx Proxy Manager Container IP address"
  value       = module.nginx_proxy_manager.ip
}
