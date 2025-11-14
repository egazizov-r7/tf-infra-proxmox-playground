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

# Create multiple LXC containers
module "lxc_containers" {
  source = "../../modules/lxc"

  for_each = var.lxc_containers

  proxmox_api_url          = var.proxmox_api_url
  proxmox_api_token_id     = var.proxmox_api_token_id
  proxmox_api_token_secret = var.proxmox_api_token_secret
  proxmox_tls_insecure     = var.proxmox_tls_insecure

  target_node         = each.value.node
  hostname            = each.value.hostname
  template            = each.value.template
  password            = each.value.password
  storage             = lookup(each.value, "storage", "local-lvm")
  disk_size           = lookup(each.value, "disk_size", "8G")
  bridge              = lookup(each.value, "bridge", "vmbr0")
  ip                  = lookup(each.value, "ip", "dhcp")
  gateway             = lookup(each.value, "gateway", "")
  memory              = lookup(each.value, "memory", 512)
  cores               = lookup(each.value, "cores", 1)
  setup_script        = lookup(each.value, "setup_script", "")
  enable_provisioning = lookup(each.value, "enable_provisioning", false)
}

# Create multiple VMs
module "vms" {
  source = "../../modules/vm"

  for_each = var.vms

  proxmox_api_url          = var.proxmox_api_url
  proxmox_api_token_id     = var.proxmox_api_token_id
  proxmox_api_token_secret = var.proxmox_api_token_secret
  proxmox_tls_insecure     = var.proxmox_tls_insecure

  target_node         = each.value.node
  vm_name             = each.value.name
  template            = each.value.template
  cores               = lookup(each.value, "cores", 2)
  memory              = lookup(each.value, "memory", 2048)
  storage             = lookup(each.value, "storage", "local-lvm")
  disk_size           = lookup(each.value, "disk_size", "20G")
  bridge              = lookup(each.value, "bridge", "vmbr0")
  ipconfig            = lookup(each.value, "ipconfig", "ip=dhcp")
  user                = lookup(each.value, "user", "debian")
  password            = each.value.password
  ssh_keys            = lookup(each.value, "ssh_keys", "")
  setup_script        = lookup(each.value, "setup_script", "")
  enable_provisioning = lookup(each.value, "enable_provisioning", false)
}
