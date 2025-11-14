terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 2.9"
    }
  }
}

resource "proxmox_lxc" "container" {
  target_node  = var.target_node
  hostname     = var.hostname
  ostemplate   = var.template
  password     = var.password
  unprivileged = true
  onboot       = true
  start        = true

  rootfs {
    storage = var.storage
    size    = var.disk_size
  }

  network {
    name   = "eth0"
    bridge = var.bridge
    ip     = var.ip
    gw     = var.gateway
  }

  memory = var.memory
  cores  = var.cores

  # Only add provisioning if enabled and not using DHCP
  dynamic "connection" {
    for_each = var.enable_provisioning && var.ip != "dhcp" ? [1] : []
    content {
      type     = "ssh"
      user     = "root"
      password = var.password
      host     = regex("([0-9.]+)", var.ip)[0]
      timeout  = "2m"
    }
  }

  # Wait for container
  provisioner "remote-exec" {
    when       = create
    on_failure = continue
    inline = var.enable_provisioning && var.ip != "dhcp" ? [
      "while [ ! -f /var/lib/dpkg/lock-frontend ]; do sleep 1; done",
      "sleep 5"
    ] : []
  }

  # Update system
  provisioner "remote-exec" {
    when       = create
    on_failure = continue
    inline = var.enable_provisioning && var.ip != "dhcp" ? [
      "apt-get update",
      "apt-get upgrade -y",
      "apt-get install -y curl wget git"
    ] : []
  }

  # Upload and run custom script if provided
  provisioner "file" {
    when        = create
    on_failure  = continue
    source      = var.setup_script != "" && var.enable_provisioning && var.ip != "dhcp" ? var.setup_script : "/dev/null"
    destination = "/tmp/setup.sh"
  }

  provisioner "remote-exec" {
    when       = create
    on_failure = continue
    inline = var.setup_script != "" && var.enable_provisioning && var.ip != "dhcp" ? [
      "chmod +x /tmp/setup.sh",
      "/tmp/setup.sh",
      "rm /tmp/setup.sh"
    ] : []
  }
}

output "id" {
  description = "Container ID"
  value       = proxmox_lxc.container.id
}

output "hostname" {
  description = "Container hostname"
  value       = proxmox_lxc.container.hostname
}

output "ip" {
  description = "Container IP"
  value       = var.ip != "dhcp" ? regex("([0-9.]+)", var.ip)[0] : "dhcp"
}
