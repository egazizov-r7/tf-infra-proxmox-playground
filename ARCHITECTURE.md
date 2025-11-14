# Service Architecture Documentation

This document provides detailed technical information about the service architecture and implementation patterns used in this project.

## 🏗️ Architecture Overview

### Design Principles

1. **Complete Isolation** - Each service is an independent Terraform module
2. **Service-Specific Configuration** - No shared state or dependencies
3. **Standardized Structure** - Consistent file organization across all services
4. **Infrastructure as Code** - Everything defined in version-controlled code
5. **Automated Deployment** - GitHub Actions for consistent deployments

### Directory Structure Pattern

Each service follows this standardized structure:

```
service_name/
├── main.tf                    # Terraform configuration
├── variables.tf               # Input variable definitions
├── outputs.tf                 # Output value definitions
├── terraform.tfvars.example   # Configuration template
└── scripts/                   # Setup scripts (optional)
    └── setup.sh
```

## 📦 Service Types

### LXC Container Services

**Location**: `instances/prod/lxc/`

LXC containers are lightweight virtualization perfect for:

- Web services and applications
- Network services (proxies, tunnels)
- Development environments
- Microservices

**Resource Requirements**: Lower CPU/RAM overhead compared to VMs

### Virtual Machine Services

**Location**: `instances/prod/vm/`

Full virtual machines suitable for:

- Operating system-specific applications
- Complex multi-service environments
- Legacy applications
- Windows workloads

**Resource Requirements**: Higher CPU/RAM overhead but full OS isolation

## 🔧 Configuration Management

### Terraform Variables

Each service uses a standard set of variables:

#### Common Variables (All Services)

```hcl
# Proxmox Connection
variable "proxmox_api_url" { }
variable "proxmox_api_token_id" { }
variable "proxmox_api_token_secret" { }
variable "proxmox_tls_insecure" { }

# Basic Configuration
variable "node" { }           # Proxmox node name
variable "password" { }       # Service password
```

#### LXC-Specific Variables

```hcl
variable "hostname" { }       # Container hostname
variable "template" { }       # Container template
variable "ip" { }            # IP configuration
variable "gateway" { }       # Network gateway
variable "memory" { }        # RAM allocation
variable "cores" { }         # CPU cores
variable "disk_size" { }     # Storage allocation
```

#### VM-Specific Variables

```hcl
variable "name" { }          # VM name
variable "template" { }      # VM template/ISO
variable "ipconfig" { }      # Network configuration
variable "user" { }          # Default user
variable "ssh_keys" { }      # SSH public keys
```

### Configuration Templates

Each service includes a `terraform.tfvars.example` with:

- Proxmox connection settings
- Service-specific configuration
- Network settings
- Resource allocations
- Setup script references

## 🚀 Deployment Architecture

### GitHub Actions Workflow

Single unified workflow: `deploy-infrastructure.yml`

```yaml
Inputs:
  service_type: lxc/service_name or vm/service_name
  action: plan | apply | destroy

Process:
1. Checkout code
2. Setup Terraform
3. Generate terraform.tfvars from template + secrets
4. Execute Terraform action
5. Display results
```

### State Management

- **Local State**: Each service manages its own `.tfstate`
- **Independent Deployment**: Services can be deployed individually
- **No Cross-Dependencies**: Services don't reference each other

## 📋 Service Specifications

### nginx_proxy_manager

**Type**: LXC Container  
**Purpose**: Web-based reverse proxy management with Let's Encrypt

```yaml
Resources:
  Memory: 1024 MB
  CPU: 2 cores
  Disk: 10G
  Network: Static IP

Features:
  - Docker-based deployment
  - Web interface on port 81
  - Automatic SSL certificates
  - Proxy host management
```

### cloudflare_tunnel

**Type**: LXC Container
**Purpose**: Secure tunnel for exposing internal services

```yaml
Resources:
  Memory: 512 MB
  CPU: 1 core
  Disk: 8G
  Network: Static IP

Features:
  - Cloudflared daemon
  - Zero-trust access
  - Automatic SSL termination
  - Configuration template included
```

### debian

**Type**: Virtual Machine
**Purpose**: General-purpose Debian system

```yaml
Resources:
  Memory: 2048 MB
  CPU: 2 cores
  Disk: 20G
  Network: Static IP or DHCP

Features:
  - Full Debian installation
  - Cloud-init support
  - SSH access
  - Package management
```

### windows_tiny10

**Type**: Virtual Machine  
**Purpose**: Lightweight Windows 10 environment

```yaml
Resources:
  Memory: 4096 MB
  CPU: 2 cores
  Disk: 40G
  Network: DHCP

Features:
  - Minimal Windows 10
  - RDP access
  - Reduced footprint
  - No provisioning (manual setup)
```

## 🔧 Setup Scripts

### Script Architecture

Setup scripts provide automated configuration after service deployment:

```bash
#!/bin/bash
# Standard script header
echo "Starting [service] setup..."

# System updates
apt-get update && apt-get upgrade -y

# Service-specific installation
# ... installation commands ...

# Configuration
# ... configuration commands ...

# Service startup
systemctl enable [service]
systemctl start [service]

echo "[Service] setup completed!"
```

### Script Guidelines

1. **Idempotent**: Safe to run multiple times
2. **Error Handling**: Check command success
3. **Logging**: Clear progress messages
4. **Dependencies**: Install all required packages
5. **Security**: Use strong defaults

## 🔍 Validation System

### Local Validation

The `validate-all.sh` script performs:

1. **File Validation**: Checks required files exist
2. **Terraform Syntax**: Validates HCL syntax
3. **Configuration Test**: Tests with example values
4. **Dependency Check**: Verifies module references

### Validation Process

```bash
For each service:
1. Check directory structure
2. Verify required files exist
3. Test Terraform init/validate
4. Report results
```

## 🔄 Maintenance & Updates

### Adding New Services

1. **Create Directory**: Follow naming convention
2. **Copy Template**: Use existing service as template
3. **Customize Configuration**: Update all files appropriately
4. **Test**: Run validation before deployment
5. **Document**: Update this documentation

### Updating Existing Services

1. **Test Changes**: Use local validation
2. **Version Control**: Commit changes with clear messages
3. **Deploy**: Use GitHub Actions for consistency
4. **Monitor**: Check deployment success

### Module Updates

When updating base modules (`modules/lxc/` or `modules/vm/`):

1. **Test Impact**: Check all services using the module
2. **Coordinate Updates**: Update services as needed
3. **Version Pin**: Consider pinning module versions for stability

## 🔐 Security Considerations

### Secrets Management

- **Never commit secrets** to version control
- **Use GitHub Secrets** for sensitive values
- **Rotate tokens** regularly
- **Limit API permissions** to minimum required

### Network Security

- **Static IPs**: Use for services requiring predictable access
- **Firewall Rules**: Configure Proxmox firewall appropriately
- **SSH Keys**: Prefer key-based authentication over passwords
- **Access Control**: Limit service exposure to required ports

### Service Security

- **Strong Passwords**: Use complex passwords for all services
- **Regular Updates**: Keep base templates and packages updated
- **Monitoring**: Implement logging and monitoring
- **Backup Strategy**: Regular backups of important data

## 📊 Performance Tuning

### Resource Allocation

- **Right-size Resources**: Start with recommendations, adjust based on usage
- **Monitor Usage**: Track CPU, memory, and disk utilization
- **Scale Appropriately**: Increase resources as needed

### Proxmox Optimization

- **Storage Performance**: Use appropriate storage backends
- **Network Performance**: Configure bridges for optimal throughput
- **Resource Scheduling**: Balance workloads across nodes

## 🔄 Backup & Recovery

### Service Backup

- **Proxmox Backup**: Use Proxmox backup solutions
- **Configuration Backup**: Version control contains all configurations
- **Data Backup**: Implement application-specific backup strategies

### Disaster Recovery

- **Infrastructure Recovery**: Redeploy using GitHub Actions
- **Data Recovery**: Restore from backups
- **Testing**: Regularly test recovery procedures
