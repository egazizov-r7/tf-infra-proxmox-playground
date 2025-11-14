terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 2.9"
    }
  }
}

resource "proxmox_vm_qemu" "vm" {
  name        = var.vm_name
  target_node = var.target_node
  clone       = var.template
  full_clone  = true
  onboot      = true
  agent       = 1

  cores   = var.cores
  sockets = 1
  memory  = var.memory

  disk {
    type    = "scsi"
    storage = var.storage
    size    = var.disk_size
  }

  network {
    model  = "virtio"
    bridge = var.bridge
  }

  os_type    = "cloud-init"
  ipconfig0  = var.ipconfig
  ciuser     = var.user
  cipassword = var.password
  sshkeys    = var.ssh_keys

  # Wait for VM to be fully ready
  provisioner "remote-exec" {
    when       = create
    on_failure = continue

    connection {
      type     = "ssh"
      user     = var.user
      password = var.password
      host     = regex("ip=([0-9.]+)", var.ipconfig)[0]
      timeout  = "15m"
    }

    inline = var.enable_provisioning && can(regex("ip=([0-9.]+)", var.ipconfig)) ? [
      # Test basic connectivity
      "echo 'VM SSH connection established'",

      # Wait for cloud-init to complete fully
      "echo 'Waiting for cloud-init to complete...'",
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Cloud-init still running...'; sleep 10; done",

      # Wait for systemd to be ready
      "sudo systemctl is-system-running --wait || true",

      # Ensure SSH service is running and properly configured
      "sudo systemctl status ssh 2>/dev/null || sudo systemctl status sshd 2>/dev/null || echo 'SSH service check completed'",

      # Wait for package manager to be available
      "while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do echo 'Waiting for package manager to be available...'; sleep 5; done",
      "while sudo fuser /var/lib/dpkg/lock >/dev/null 2>&1; do echo 'Waiting for dpkg lock...'; sleep 5; done",

      # Ensure system is stable
      "sleep 15",
      "echo 'VM initialization completed'"
    ] : []
  }

  # Update system packages
  provisioner "remote-exec" {
    when       = create
    on_failure = continue

    connection {
      type     = "ssh"
      user     = var.user
      password = var.password
      host     = regex("ip=([0-9.]+)", var.ipconfig)[0]
      timeout  = "15m"
    }

    inline = var.enable_provisioning && can(regex("ip=([0-9.]+)", var.ipconfig)) ? [
      "echo 'Starting system update...'",
      "sudo apt-get update",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold'",
      "sudo apt-get install -y curl wget git nano htop qemu-guest-agent",
      "sudo systemctl enable qemu-guest-agent",
      "sudo systemctl start qemu-guest-agent",
      "echo 'System update completed'"
    ] : []
  }

  # Upload and run custom script if provided
  provisioner "file" {
    when       = create
    on_failure = continue

    connection {
      type     = "ssh"
      user     = var.user
      password = var.password
      host     = regex("ip=([0-9.]+)", var.ipconfig)[0]
      timeout  = "10m"
    }

    source      = var.setup_script != "" && var.enable_provisioning && can(regex("ip=([0-9.]+)", var.ipconfig)) ? var.setup_script : "/dev/null"
    destination = "/tmp/setup.sh"
  }

  provisioner "remote-exec" {
    when       = create
    on_failure = continue

    connection {
      type     = "ssh"
      user     = var.user
      password = var.password
      host     = regex("ip=([0-9.]+)", var.ipconfig)[0]
      timeout  = "20m"
    }

    inline = var.setup_script != "" && var.enable_provisioning && can(regex("ip=([0-9.]+)", var.ipconfig)) ? [
      "echo 'Running custom setup script...'",
      "chmod +x /tmp/setup.sh",
      "sudo /tmp/setup.sh",
      "rm /tmp/setup.sh",
      "echo 'Custom setup script completed'"
    ] : []
  }
}

output "id" {
  description = "VM ID"
  value       = proxmox_vm_qemu.vm.id
}

output "name" {
  description = "VM name"
  value       = proxmox_vm_qemu.vm.name
}

output "ip" {
  description = "VM IP"
  value       = can(regex("ip=([0-9.]+)", var.ipconfig)) ? regex("ip=([0-9.]+)", var.ipconfig)[0] : "dhcp"
}
