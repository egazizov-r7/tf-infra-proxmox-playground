# Cloudflare Tunnel Container Outputs
output "container_id" {
  description = "Cloudflare Tunnel Container ID"
  value       = module.cloudflare_tunnel.id
}

output "container_hostname" {
  description = "Cloudflare Tunnel Container hostname"
  value       = module.cloudflare_tunnel.hostname
}

output "container_ip" {
  description = "Cloudflare Tunnel Container IP address"
  value       = module.cloudflare_tunnel.ip
}
