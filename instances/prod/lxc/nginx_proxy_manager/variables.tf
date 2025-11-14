# Proxmox Provider Variables
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
  description = "Skip TLS verification"
  type        = bool
  default     = true
}

# Container Configuration Variables
variable "node" {
  description = "Proxmox node name"
  type        = string
}

variable "hostname" {
  description = "Container hostname"
  type        = string
}

variable "template" {
  description = "Container template"
  type        = string
}

variable "password" {
  description = "Container root password"
  type        = string
  sensitive   = true
}

variable "storage" {
  description = "Storage location"
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

variable "ip" {
  description = "IP address with CIDR"
  type        = string
}

variable "gateway" {
  description = "Gateway IP address"
  type        = string
}

variable "memory" {
  description = "Memory in MB"
  type        = number
  default     = 1024
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
  description = "Enable provisioning"
  type        = bool
  default     = false
}
