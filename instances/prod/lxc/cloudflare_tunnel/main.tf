terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 2.9"
    }
  }
  required_version = ">= 1.0"
}

provider "proxmox" {
  pm_api_url          = var.proxmox_api_url
  pm_api_token_id     = var.proxmox_api_token_id
  pm_api_token_secret = var.proxmox_api_token_secret
  pm_tls_insecure     = var.proxmox_tls_insecure
}

# Cloudflare Tunnel LXC Container
module "cloudflare_tunnel" {
  source = "../../../../modules/lxc"

  proxmox_api_url          = var.proxmox_api_url
  proxmox_api_token_id     = var.proxmox_api_token_id
  proxmox_api_token_secret = var.proxmox_api_token_secret
  proxmox_tls_insecure     = var.proxmox_tls_insecure

  target_node         = var.node
  hostname            = var.hostname
  template            = var.template
  password            = var.password
  storage             = var.storage
  disk_size           = var.disk_size
  bridge              = var.bridge
  ip                  = var.ip
  gateway             = var.gateway
  memory              = var.memory
  cores               = var.cores
  setup_script        = var.setup_script
  enable_provisioning = var.enable_provisioning
}
