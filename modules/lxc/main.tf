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

  # Wait for container to be fully ready
  provisioner "remote-exec" {
    when       = create
    on_failure = continue

    connection {
      type     = "ssh"
      user     = "root"
      password = var.password
      host     = regex("([0-9.]+)", var.ip)[0]
      timeout  = "10m"
    }

    inline = var.enable_provisioning && var.ip != "dhcp" ? [
      # Test basic connectivity
      "echo 'Container SSH connection established'",

      # Wait for systemd to be ready
      "systemctl is-system-running --wait || true",

      # Ensure SSH service is running (in case it's not in template)
      "systemctl status ssh 2>/dev/null || (apt-get update && apt-get install -y openssh-server && systemctl enable ssh && systemctl start ssh)",

      # Wait for package manager to be available
      "while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do echo 'Waiting for package manager to be available...'; sleep 5; done",
      "while fuser /var/lib/dpkg/lock >/dev/null 2>&1; do echo 'Waiting for dpkg lock...'; sleep 5; done",

      # Ensure system is stable
      "sleep 10",
      "echo 'Container initialization completed'"
    ] : []
  }

  # Update system packages
  provisioner "remote-exec" {
    when       = create
    on_failure = continue

    connection {
      type     = "ssh"
      user     = "root"
      password = var.password
      host     = regex("([0-9.]+)", var.ip)[0]
      timeout  = "10m"
    }

    inline = var.enable_provisioning && var.ip != "dhcp" ? [
      "echo 'Starting system update...'",
      "apt-get update",
      "DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold'",
      "apt-get install -y curl wget git nano htop",
      "echo 'System update completed'"
    ] : []
  }

  # Upload and run custom script if provided
  provisioner "file" {
    when       = create
    on_failure = continue

    connection {
      type     = "ssh"
      user     = "root"
      password = var.password
      host     = regex("([0-9.]+)", var.ip)[0]
      timeout  = "5m"
    }

    source      = var.setup_script != "" && var.enable_provisioning && var.ip != "dhcp" ? var.setup_script : "/dev/null"
    destination = "/tmp/setup.sh"
  }

  provisioner "remote-exec" {
    when       = create
    on_failure = continue

    connection {
      type     = "ssh"
      user     = "root"
      password = var.password
      host     = regex("([0-9.]+)", var.ip)[0]
      timeout  = "15m"
    }

    inline = var.setup_script != "" && var.enable_provisioning && var.ip != "dhcp" ? [
      "echo 'Running custom setup script...'",
      "chmod +x /tmp/setup.sh",
      "/tmp/setup.sh",
      "rm /tmp/setup.sh",
      "echo 'Custom setup script completed'"
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
