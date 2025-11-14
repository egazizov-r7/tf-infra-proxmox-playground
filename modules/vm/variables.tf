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

variable "vm_name" {
  description = "VM name"
  type        = string
}

variable "template" {
  description = "VM template to clone from"
  type        = string
}

variable "cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 2
}

variable "memory" {
  description = "Memory in MB"
  type        = number
  default     = 2048
}

variable "storage" {
  description = "Storage name"
  type        = string
  default     = "local-lvm"
}

variable "disk_size" {
  description = "Disk size"
  type        = string
  default     = "20G"
}

variable "bridge" {
  description = "Network bridge"
  type        = string
  default     = "vmbr0"
}

variable "ipconfig" {
  description = "IP configuration"
  type        = string
  default     = "ip=dhcp"
}

variable "user" {
  description = "Cloud-init user"
  type        = string
  default     = "debian"
}

variable "password" {
  description = "User password"
  type        = string
  sensitive   = true
}

variable "ssh_keys" {
  description = "SSH public keys"
  type        = string
  default     = ""
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
