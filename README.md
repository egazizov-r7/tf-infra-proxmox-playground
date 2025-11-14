# Proxmox Infrastructure as Code

A scalable Terraform solution for deploying and managing multiple LXC containers and VMs on Proxmox, with automated deployment via GitHub Actions.

> **✅ Production-Ready Configuration**: This project contains only production-ready configurations. Run `./verify-structure.sh` to confirm.

## Project Structure

```
tf-infra-proxmox/
├── modules/                      # Reusable Terraform modules
│   ├── lxc/                     # LXC container module
│   │   ├── main.tf
│   │   └── variables.tf
│   └── vm/                      # VM module
│       ├── main.tf
│       └── variables.tf
├── instances/                    # Production configuration
│   └── prod/                    # Production environment
│       ├── main.tf              # Uses modules to create multiple resources
│       ├── variables.tf
│       ├── outputs.tf
│       ├── terraform.tfvars.example
│       └── scripts/             # Production setup scripts
│           ├── web-setup.sh
│           ├── db-setup.sh
│           └── app-setup.sh
├── .github/
│   ├── workflows/
│   │   ├── deploy-infrastructure.yml  # Deploy all (LXC + VMs)
│   │   ├── deploy-lxc.yml            # Deploy LXC only
│   │   └── deploy-vm.yml             # Deploy VMs only
│   └── examples/                # Example configurations for GitHub variables
│       ├── lxc_containers.json
│       └── vms.json
└── README.md
```

## Key Features

✅ **Multi-Instance Support**: Deploy multiple LXC containers and VMs in a single configuration  
✅ **Modular Design**: Reusable modules for consistent deployments  
✅ **Separate Workflows**: Deploy all, LXC only, or VMs only via GitHub Actions  
✅ **Flexible Provisioning**: Optional automated setup scripts per instance  
✅ **Action Control**: Plan, apply, or destroy via workflow inputs  
✅ **DHCP & Static IP**: Support for both network configurations

## Prerequisites

- Proxmox VE server (7.x or later)
- **For LXC**: Debian container templates
- **For VM**: Cloud-init enabled VM templates
- Proxmox API token for authentication
- GitHub repository with Actions enabled

## Quick Start

### 1. Prepare Proxmox

#### Create API Token

1. Log in to your Proxmox web interface
2. Go to **Datacenter** → **Permissions** → **API Tokens**
3. Click **Add** and create a token:
   - User: `terraform@pam`
   - Token ID: `terraform`
   - Privilege Separation: Unchecked
4. Save the token secret

#### For LXC: Upload Templates

```bash
pveam update
pveam download local debian-12-standard_12.2-1_amd64.tar.zst
```

#### For VM: Create Cloud-Init Template

```bash
wget https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2
# Create template in Proxmox (see Proxmox docs for detailed steps)
```

### 2. Configure GitHub

#### Add Secrets

Navigate to: **Settings** → **Secrets and variables** → **Actions** → **Secrets**

- `PROXMOX_API_URL`: `https://your-proxmox-host:8006/api2/json`
- `PROXMOX_API_TOKEN_ID`: `terraform@pam!terraform`
- `PROXMOX_API_TOKEN_SECRET`: Your token secret

#### Add Variables

Navigate to: **Settings** → **Secrets and variables** → **Actions** → **Variables**

**Method 1: Simple Configuration (Recommended for testing)**

- `LXC_CONTAINERS`: Copy content from `.github/examples/lxc_containers.json`
- `VMS`: Copy content from `.github/examples/vms.json`
- Replace `REPLACE_WITH_SECRET` placeholders with actual passwords

**Method 2: Use Secrets for Passwords (Production)**
Create additional secrets for each instance password, then reference them in the JSON configuration.

### 3. Deploy Infrastructure

#### Via GitHub Actions

You have three workflow options:

**Option 1: Deploy All Infrastructure (LXC + VMs)**

1. Go to **Actions** tab
2. Select **Deploy All Infrastructure**
3. Click **Run workflow**
4. Choose action: `plan`, `apply`, or `destroy`

**Option 2: Deploy LXC Containers Only**

1. Go to **Actions** tab
2. Select **Deploy LXC Containers**
3. Click **Run workflow**
4. Choose action: `plan`, `apply`, or `destroy`

**Option 3: Deploy VMs Only**

1. Go to **Actions** tab
2. Select **Deploy VMs**
3. Click **Run workflow**
4. Choose action: `plan`, `apply`, or `destroy`

#### Local Deployment

```bash
cd instances/prod
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your configuration
terraform init
terraform plan
terraform apply
```

## Configuration Guide

### Defining Multiple Instances

Edit `instances/prod/terraform.tfvars.example` to define your infrastructure:

```hcl
lxc_containers = {
  "web-server" = {
    node         = "pve"
    hostname     = "web-01"
    template     = "local:vztmpl/debian-12-standard_12.2-1_amd64.tar.zst"
    password     = "secure-password"
    ip           = "192.168.1.101/24"
    gateway      = "192.168.1.1"
    memory       = 1024
    cores        = 2
    disk_size    = "10G"
    setup_script = "${path.module}/scripts/web-setup.sh"
    enable_provisioning = true
  },

  "database" = {
    node     = "pve"
    hostname = "db-01"
    template = "local:vztmpl/debian-12-standard_12.2-1_amd64.tar.zst"
    password = "secure-password"
    ip       = "192.168.1.102/24"
    gateway  = "192.168.1.1"
    memory   = 2048
    cores    = 2
    disk_size = "20G"
    setup_script = "${path.module}/scripts/db-setup.sh"
    enable_provisioning = true
  }
}

vms = {
  "app-server" = {
    node     = "pve"
    name     = "app-01"
    template = "debian-12-cloudinit"
    password = "secure-password"
    user     = "debian"
    ipconfig = "ip=192.168.1.201/24,gw=192.168.1.1"
    cores    = 4
    memory   = 4096
    disk_size = "40G"
    setup_script = "${path.module}/scripts/app-setup.sh"
    enable_provisioning = true
  }
}
```

### Adding/Removing Instances

**Add a new LXC container:**

```hcl
lxc_containers = {
  # ... existing containers ...

  "new-service" = {
    node     = "pve"
    hostname = "service-01"
    template = "local:vztmpl/debian-12-standard_12.2-1_amd64.tar.zst"
    password = "password"
    ip       = "dhcp"  # or static IP
    memory   = 512
    cores    = 1
  }
}
```

**Remove an instance:**  
Simply delete the block from the configuration and run `terraform apply`

### Custom Setup Scripts

Each instance can have its own setup script:

1. Create script in `instances/prod/scripts/your-script.sh`
2. Reference it in the configuration:
   ```hcl
   setup_script = "${path.module}/scripts/your-script.sh"
   enable_provisioning = true
   ```

**Note:** Provisioning only works with static IPs (not DHCP)

## Module Architecture

### LXC Module (`modules/lxc/`)

Reusable module for creating LXC containers with:

- Configurable resources (CPU, memory, disk)
- Network configuration (static IP or DHCP)
- Optional automated provisioning
- Custom setup script support

### VM Module (`modules/vm/`)

Reusable module for creating VMs with:

- Cloud-init integration
- Configurable resources
- Network configuration
- Optional automated provisioning
- Custom setup script support

### Instance Configuration (`instances/prod/`)

Uses modules with `for_each` to create multiple instances:

```hcl
module "lxc_containers" {
  source = "../../modules/lxc"
  for_each = var.lxc_containers
  # ... configuration ...
}
```

## Scaling Examples

### Deploy 10 identical web servers:

```hcl
lxc_containers = {
  for i in range(1, 11) : "web-${i}" => {
    node     = "pve"
    hostname = "web-${format("%02d", i)}"
    template = "local:vztmpl/debian-12-standard_12.2-1_amd64.tar.zst"
    password = var.web_password
    ip       = "192.168.1.${100 + i}/24"
    gateway  = "192.168.1.1"
    memory   = 1024
    cores    = 2
  }
}
```

### Different instance types:

```hcl
lxc_containers = {
  "nginx-lb"   = { memory = 512,  cores = 1, disk_size = "8G"  },
  "app-01"     = { memory = 2048, cores = 2, disk_size = "20G" },
  "app-02"     = { memory = 2048, cores = 2, disk_size = "20G" },
  "postgres"   = { memory = 4096, cores = 4, disk_size = "50G" },
  "redis"      = { memory = 1024, cores = 1, disk_size = "10G" },
}
```

## GitHub Actions Workflows

This project includes three separate workflows for flexible deployment:

### 1. Deploy All Infrastructure

**Workflow**: `deploy-infrastructure.yml`  
**Purpose**: Deploy both LXC containers and VMs together  
**Use case**: Initial setup or updating all infrastructure

### 2. Deploy LXC Containers

**Workflow**: `deploy-lxc.yml`  
**Purpose**: Deploy only LXC containers (VMs unchanged)  
**Use case**: Add/update containers without affecting VMs  
**Target**: Uses `-target='module.lxc_containers'`

### 3. Deploy VMs

**Workflow**: `deploy-vm.yml`  
**Purpose**: Deploy only VMs (LXC containers unchanged)  
**Use case**: Add/update VMs without affecting containers  
**Target**: Uses `-target='module.vms'`

### Workflow Actions

All workflows support three actions:

- **plan**: Preview changes without applying
- **apply**: Apply changes to infrastructure
- **destroy**: Remove infrastructure

### Required GitHub Secrets

- `PROXMOX_API_URL`
- `PROXMOX_API_TOKEN_ID`
- `PROXMOX_API_TOKEN_SECRET`

### Required GitHub Variables

- `LXC_CONTAINERS`: JSON configuration for LXC containers
- `VMS`: JSON configuration for VMs

See `.github/examples/` for configuration examples.

## Best Practices

1. **Use Separate Environments**: Keep dev/staging/prod configurations isolated
2. **Version Control**: Commit configuration files, not `terraform.tfvars`
3. **State Management**: Consider using remote state (S3, Terraform Cloud) for teams
4. **Naming Convention**: Use consistent naming (e.g., `service-number`)

## Best Practices

1. **Version Control**: Commit configuration files, not `terraform.tfvars`
2. **State Management**: Consider using remote state (S3, Terraform Cloud) for teams
3. **Naming Convention**: Use consistent naming (e.g., `service-number`)
4. **Resource Tags**: Use meaningful map keys for easy identification
5. **Provisioning**: Disable `enable_provisioning` for DHCP instances
6. **Secrets**: Never commit passwords; use GitHub Secrets or Vault
7. **Backup**: Regularly backup Terraform state files

## Clean Up

**Destroy specific instance:**

```bash
cd instances/prod
terraform destroy -target='module.lxc_containers["web-server"]'
```

**Destroy all instances:**

```bash
cd instances/prod
terraform destroy
```

**Remove single instance without destroying:**  
Remove from configuration file and run `terraform apply`

### API Authentication Issues

- Verify API token has correct permissions
- Check if privilege separation is disabled for the token
- Ensure the API URL is correct (include port 8006)

### LXC: Template Not Found

- Verify template exists: `pveam list local`
- Check the template path format matches your storage configuration

### VM: Template Not Found

- Verify template exists in Proxmox web interface
- Ensure the template name matches exactly
- Check that cloud-init is properly configured on the template

### Network/SSH Issues

- Ensure the bridge name matches your Proxmox network configuration
- For static IPs, verify the IP is not already in use
- Check gateway is correct for your network
- **For GitHub Actions**: Ensure the runner can reach the container/VM IP
- Wait a few moments for SSH to become available after creation
- Check firewall rules aren't blocking SSH (port 22)

### Provisioner Failures

- If scripts fail, check the script permissions and syntax
- Ensure the container/VM has internet access for package installation
- For VMs, verify qemu-guest-agent is installed and running

## Key Differences: LXC vs VM

| Feature            | LXC Container                    | VM                                 |
| ------------------ | -------------------------------- | ---------------------------------- |
| **Resource Usage** | Lightweight, shared kernel       | Full OS, more overhead             |
| **Boot Time**      | Seconds                          | Minutes                            |
| **Template Type**  | Container template (.tar.zst)    | Disk image with cloud-init         |
| **Use Case**       | Services, apps, dev environments | Full OS isolation, Windows support |
| **SSH User**       | root                             | Custom user (cloud-init)           |
| **Memory**         | Typically 512MB-2GB              | Typically 2GB+                     |
| **Provisioning**   | Direct root access               | sudo required                      |

## Security Notes

- Never commit `terraform.tfvars` to version control
- Use strong passwords for containers and VMs
- Consider using SSH keys instead of passwords for VMs
- Use a firewall to restrict Proxmox API access
- Regularly update Proxmox, templates, and deployed systems
- Review and customize the setup scripts before deployment
