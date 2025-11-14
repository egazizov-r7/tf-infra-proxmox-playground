# Proxmox Infrastructure as Code

A streamlined Terraform solution for deploying and managing infrastructure on Proxmox with individual service isolation and automated deployment via GitHub Actions.

> **🎯 Clean & Modular**: Each service (LXC container or VM) is completely isolated with its own Terraform configuration for maximum flexibility and maintainability.

## 🏗️ Project Structure

```
tf-infra-proxmox-playground/
├── modules/                     # Reusable Terraform modules
│   ├── lxc/                    # LXC container module
│   └── vm/                     # Virtual machine module
├── instances/prod/             # Production services
│   ├── lxc/                   # LXC-based services
│   │   ├── nginx_proxy_manager/
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   ├── terraform.tfvars.example
│   │   │   └── scripts/
│   │   │       └── nginx-proxy-setup.sh
│   │   └── cloudflare_tunnel/
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       ├── outputs.tf
│   │       ├── terraform.tfvars.example
│   │       └── scripts/
│   │           └── cloudflare-tunnel-setup.sh
│   ├── vm/                    # Virtual machine services
│   │   ├── debian/
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   └── terraform.tfvars.example
│   │   └── windows_tiny10/
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       ├── outputs.tf
│   │       └── terraform.tfvars.example
│   └── validate-all.sh        # Validation tool
├── .github/workflows/
│   └── deploy-infrastructure.yml  # Unified deployment workflow
└── README.md
```

## ✨ Key Features

✅ **Complete Isolation**: Each service is an independent Terraform module  
✅ **Service-Specific**: Tailored configurations for each service type  
✅ **Unified Deployment**: Single GitHub Actions workflow for all services  
✅ **Local Validation**: Test configurations before deployment  
✅ **Clean Structure**: No redundant files or complex dependencies  
✅ **Easy Scaling**: Add new services by copying and customizing existing ones

## 📋 Available Services

### LXC Containers

- **Nginx Proxy Manager** (`lxc/nginx_proxy_manager`) - Web-based reverse proxy management
- **Cloudflare Tunnel** (`lxc/cloudflare_tunnel`) - Secure tunnel to Cloudflare network

### Virtual Machines

- **Debian VM** (`vm/debian`) - Standard Debian virtual machine
- **Windows Tiny10** (`vm/windows_tiny10`) - Lightweight Windows 10 VM

## 🚀 Quick Start

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

````bash
wget https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2
# Create template in Proxmox (see Proxmox docs for detailed steps)
## 📋 Prerequisites

### Proxmox Environment
- **Proxmox VE** 7.x or later
- **API Access** with token-based authentication
- **LXC Templates** for container services (Debian 12 recommended)
- **VM Templates/ISOs** for virtual machine deployments

### GitHub Repository
- **GitHub Actions** enabled
- **Secrets configured** for Proxmox API access

## ⚙️ Setup Instructions

### 1. Prepare Proxmox

#### Create API Token
```bash
# In Proxmox web interface:
# Datacenter → Permissions → API Tokens → Add
# User: terraform@pam
# Token ID: terraform
# Privilege Separation: Unchecked
````

#### Upload LXC Templates (for LXC services)

```bash
pveam update
pveam download local debian-12-standard_12.2-1_amd64.tar.zst
```

### 2. Configure GitHub Secrets

Navigate to: **Repository Settings** → **Secrets and variables** → **Actions** → **Secrets**

Add these secrets:

- `PROXMOX_API_URL`: `https://your-proxmox-host:8006/api2/json`
- `PROXMOX_API_TOKEN_ID`: `terraform@pam!terraform`
- `PROXMOX_API_TOKEN_SECRET`: Your generated token secret

### 3. Validate Configuration (Optional)

Test all service configurations locally:

```bash
cd instances/prod
./validate-all.sh
```

## 🚀 Deployment Methods

### Method 1: GitHub Actions (Recommended)

1. **Navigate to Actions tab** in your GitHub repository
2. **Select "Deploy Infrastructure"** workflow
3. **Choose service** from dropdown:
   - `lxc/nginx_proxy_manager`
   - `lxc/cloudflare_tunnel`
   - `vm/debian`
   - `vm/windows_tiny10`
4. **Select action**: `plan`, `apply`, or `destroy`
5. **Click "Run workflow"**

### Method 2: Local Deployment

```bash
# Navigate to specific service
cd instances/prod/lxc/nginx_proxy_manager

# Copy and edit configuration
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your settings

# Deploy
terraform init
terraform plan
terraform apply
```

## 📝 Service Configuration

Each service has its own `terraform.tfvars.example` with all necessary configuration options:

### Example: Nginx Proxy Manager

```hcl
# Proxmox Connection
proxmox_api_url          = "https://your-proxmox:8006/api2/json"
proxmox_api_token_id     = "terraform@pam!terraform"
proxmox_api_token_secret = "your-token-secret"

# Container Settings
node = "pve"
hostname = "nginx-proxy-manager"
template = "local:vztmpl/debian-12-standard_12.2-1_amd64.tar.zst"
ip = "192.168.1.100/24"
memory = 1024
cores = 2
# ... additional settings
```

## 📦 Adding New Services

### 1. Create Service Directory

```bash
mkdir -p instances/prod/lxc/my_new_service
# or
mkdir -p instances/prod/vm/my_new_vm
```

### 2. Copy Template Files

```bash
# For LXC service
cp instances/prod/lxc/nginx_proxy_manager/* instances/prod/lxc/my_new_service/

# For VM service
cp instances/prod/vm/debian/* instances/prod/vm/my_new_vm/
```

### 3. Customize Configuration

- Edit `main.tf` - Update module name and description
- Edit `terraform.tfvars.example` - Set service-specific values
- Edit `outputs.tf` - Update output descriptions
- Create `scripts/` directory with setup scripts if needed

### 4. Deploy

Use the GitHub Actions workflow with your new service path.

## 🔧 Advanced Configuration

### Custom Setup Scripts

Each service can include automated setup scripts:

```bash
# Create scripts directory
mkdir instances/prod/lxc/my_service/scripts

# Create setup script
cat > instances/prod/lxc/my_service/scripts/setup.sh << 'EOF'
#!/bin/bash
echo "Setting up my service..."
# Your setup commands here
EOF

# Reference in terraform.tfvars.example
setup_script = "./scripts/setup.sh"
enable_provisioning = true
```

### Network Configuration

#### Static IP Configuration

```hcl
# For LXC containers
ip = "192.168.1.100/24"
gateway = "192.168.1.1"

# For VMs
ipconfig = "ip=192.168.1.200/24,gw=192.168.1.1"
```

#### DHCP Configuration

```hcl
# For LXC containers
ip = "dhcp"

# For VMs
ipconfig = "ip=dhcp"
```

## 🔍 Validation & Testing

### Validate All Services

```bash
cd instances/prod
./validate-all.sh
```

### Validate Individual Service

```bash
cd instances/prod/lxc/nginx_proxy_manager
terraform init -backend=false
terraform validate
```

### Test Service Configuration

```bash
# Copy example configuration
cp terraform.tfvars.example terraform.tfvars
# Edit with test values
terraform plan  # Review planned changes
```

## 📚 Service Documentation

### Nginx Proxy Manager

- **Purpose**: Web-based reverse proxy management with Let's Encrypt integration
- **Access**: `http://container-ip:81` (default: admin@example.com/changeme)
- **Features**: SSL certificates, proxy hosts, access lists

### Cloudflare Tunnel

- **Purpose**: Secure tunnel to expose internal services via Cloudflare
- **Setup**: Requires Cloudflare account and tunnel configuration
- **Features**: Zero-trust access, automatic SSL, DDoS protection

### Debian VM

- **Purpose**: General-purpose Debian virtual machine
- **Features**: Full VM with cloud-init support, SSH access
- **Use Cases**: Development, hosting applications, general computing

### Windows Tiny10

- **Purpose**: Lightweight Windows 10 virtual machine
- **Features**: Minimal Windows installation, RDP access
- **Use Cases**: Windows-specific applications, testing

## 🛠️ Troubleshooting

### Common Issues

#### Authentication Failed

```bash
# Check API token permissions in Proxmox
# Ensure token has necessary privileges
```

#### Template Not Found

```bash
# List available templates
pveam list local

# Download required template
pveam download local debian-12-standard_12.2-1_amd64.tar.zst
```

#### Network Configuration Issues

```bash
# Check Proxmox network bridges
ip link show

# Verify bridge configuration matches terraform.tfvars
```

### Debug Mode

```bash
# Enable Terraform debug logging
export TF_LOG=DEBUG
terraform apply
```

## 🤝 Contributing

1. **Fork** the repository
2. **Create feature branch**: `git checkout -b feature/new-service`
3. **Add your service** following the established patterns
4. **Test configuration**: Run `./validate-all.sh`
5. **Submit pull request** with clear description

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🔗 Related Resources

- [Proxmox VE Documentation](https://pve.proxmox.com/wiki/Main_Page)
- [Terraform Proxmox Provider](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
  "app-server" = {
  node = "pve"
  name = "app-01"
  template = "debian-12-cloudinit"
  password = "secure-password"
  user = "debian"
  ipconfig = "ip=192.168.1.201/24,gw=192.168.1.1"
  cores = 4
  memory = 4096
  disk_size = "40G"
  setup_script = "${path.module}/scripts/app-setup.sh"
  enable_provisioning = true
  }
  }

````

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
````

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
