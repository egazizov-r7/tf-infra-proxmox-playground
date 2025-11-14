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

  # Only add provisioning if enabled and static IP
  dynamic "connection" {
    for_each = var.enable_provisioning && can(regex("ip=([0-9.]+)", var.ipconfig)) ? [1] : []
    content {
      type     = "ssh"
      user     = var.user
      password = var.password
      host     = regex("ip=([0-9.]+)", var.ipconfig)[0]
      timeout  = "5m"
    }
  }

  provisioner "remote-exec" {
    when       = create
    on_failure = continue
    inline = var.enable_provisioning && can(regex("ip=([0-9.]+)", var.ipconfig)) ? [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do sleep 1; done",
      "sleep 5"
    ] : []
  }

  provisioner "remote-exec" {
    when       = create
    on_failure = continue
    inline = var.enable_provisioning && can(regex("ip=([0-9.]+)", var.ipconfig)) ? [
      "sudo apt-get update",
      "sudo apt-get upgrade -y",
      "sudo apt-get install -y curl wget git qemu-guest-agent"
    ] : []
  }

  provisioner "file" {
    when        = create
    on_failure  = continue
    source      = var.setup_script != "" && var.enable_provisioning && can(regex("ip=([0-9.]+)", var.ipconfig)) ? var.setup_script : "/dev/null"
    destination = "/tmp/setup.sh"
  }

  provisioner "remote-exec" {
    when       = create
    on_failure = continue
    inline = var.setup_script != "" && var.enable_provisioning && can(regex("ip=([0-9.]+)", var.ipconfig)) ? [
      "chmod +x /tmp/setup.sh",
      "sudo /tmp/setup.sh",
      "rm /tmp/setup.sh"
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
