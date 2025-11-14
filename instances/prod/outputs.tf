# Output information about created resources
output "lxc_containers" {
  description = "Information about created LXC containers"
  value = {
    for key, container in module.lxc_containers : key => {
      id       = container.id
      hostname = container.hostname
      ip       = container.ip
    }
  }
}

output "vms" {
  description = "Information about created VMs"
  value = {
    for key, vm in module.vms : key => {
      id   = vm.id
      name = vm.name
      ip   = vm.ip
    }
  }
}
