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

variable "target_node" {
  description = "Proxmox node name"
  type        = string
}

variable "hostname" {
  description = "LXC container hostname"
  type        = string
}

variable "template" {
  description = "Container template path"
  type        = string
}

variable "password" {
  description = "Root password"
  type        = string
  sensitive   = true
}

variable "storage" {
  description = "Storage name"
  type        = string
  default     = "local-lvm"
}

variable "disk_size" {
  description = "Root filesystem size"
  type        = string
  default     = "8G"
}

variable "bridge" {
  description = "Network bridge"
  type        = string
  default     = "vmbr0"
}

variable "ip" {
  description = "IP address with CIDR or dhcp"
  type        = string
  default     = "dhcp"
}

variable "gateway" {
  description = "Gateway IP address"
  type        = string
  default     = ""
}

variable "memory" {
  description = "Memory in MB"
  type        = number
  default     = 512
}

variable "cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 1
}

variable "setup_script" {
  description = "Path to setup script"
  type        = string
  default     = ""
}

variable "enable_provisioning" {
  description = "Enable remote provisioning"
  type        = bool
  default     = true
}
