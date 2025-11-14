variable "proxmox_api_url" {
  description = "Proxmox API URL"
  type        = string
}

variable "proxmox_api_token_id" {
  description = "Proxmox API Token ID"
  type        = string
}

variable "proxmox_api_token_secret" {
  description = "Proxmox API Token Secret"
  type        = string
  sensitive   = true
}

variable "proxmox_tls_insecure" {
  description = "Allow insecure TLS connection"
  type        = bool
  default     = true
}

variable "lxc_containers" {
  description = "Map of LXC containers to create"
  type = map(object({
    node                = string
    hostname            = string
    template            = string
    password            = string
    storage             = optional(string)
    disk_size           = optional(string)
    bridge              = optional(string)
    ip                  = optional(string)
    gateway             = optional(string)
    memory              = optional(number)
    cores               = optional(number)
    setup_script        = optional(string)
    enable_provisioning = optional(bool)
  }))
  default = {}
}

variable "vms" {
  description = "Map of VMs to create"
  type = map(object({
    node                = string
    name                = string
    template            = string
    password            = string
    cores               = optional(number)
    memory              = optional(number)
    storage             = optional(string)
    disk_size           = optional(string)
    bridge              = optional(string)
    ipconfig            = optional(string)
    user                = optional(string)
    ssh_keys            = optional(string)
    setup_script        = optional(string)
    enable_provisioning = optional(bool)
  }))
  default = {}
}
