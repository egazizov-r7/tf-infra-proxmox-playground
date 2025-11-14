# Deployment Guide

This guide provides step-by-step instructions for deploying and configuring each service.

## 🚀 Before You Start

### Prerequisites Checklist

- [ ] Proxmox VE server accessible
- [ ] API token created in Proxmox
- [ ] GitHub secrets configured
- [ ] Required templates/ISOs uploaded to Proxmox
- [ ] Network configuration planned

### Quick Validation

```bash
# Clone repository
git clone https://github.com/egazizov-r7/tf-infra-proxmox-playground.git
cd tf-infra-proxmox-playground/instances/prod

# Validate all configurations
./validate-all.sh
```

## 📋 Service Deployment Guides

### 🔄 Nginx Proxy Manager

**Purpose**: Centralized reverse proxy management with automatic SSL certificates

#### Prerequisites

```bash
# Ensure Debian template is available
pveam list local | grep debian-12
```

#### Deployment Steps

1. **Navigate to GitHub Actions**

   - Go to your repository's Actions tab
   - Select "Deploy Infrastructure" workflow

2. **Configure Deployment**

   - Service Type: `lxc/nginx_proxy_manager`
   - Action: `plan` (to preview) or `apply` (to deploy)

3. **Review Configuration**

   - Default IP: `192.168.1.100/24`
   - Memory: 1024 MB
   - CPU: 2 cores
   - Disk: 10G

4. **Post-Deployment Setup**

   ```bash
   # Access web interface
   http://192.168.1.100:81

   # Default credentials
   Email: admin@example.com
   Password: changeme
   ```

5. **Initial Configuration**
   - Change default admin password
   - Configure your first proxy host
   - Set up SSL certificate (Let's Encrypt)

#### Customization

Edit `instances/prod/lxc/nginx_proxy_manager/terraform.tfvars.example`:

```hcl
# Custom network settings
ip = "192.168.1.50/24"
gateway = "192.168.1.1"

# Resource adjustments
memory = 2048  # Increase for high traffic
cores = 4      # More CPU for SSL processing
```

### 🌐 Cloudflare Tunnel

**Purpose**: Secure tunnel for exposing internal services without opening firewall ports

#### Prerequisites

```bash
# Cloudflare account required
# Domain configured in Cloudflare
```

#### Deployment Steps

1. **Deploy Container**

   - Service Type: `lxc/cloudflare_tunnel`
   - Action: `apply`

2. **Cloudflare Setup**

   ```bash
   # Login to Cloudflare Dashboard
   # Navigate to Zero Trust → Networks → Tunnels
   # Create a new tunnel
   # Download the credentials file
   ```

3. **Configure Tunnel**

   ```bash
   # SSH into the container
   ssh root@192.168.1.110

   # Upload credentials file to /etc/cloudflared/
   # Edit /etc/cloudflared/config.yml
   ```

4. **Example Configuration**

   ```yaml
   tunnel: your-tunnel-id
   credentials-file: /etc/cloudflared/your-tunnel-id.json

   ingress:
     - hostname: nginx.example.com
       service: http://192.168.1.100:81
     - hostname: app.example.com
       service: http://192.168.1.200:8080
     - service: http_status:404
   ```

5. **Start Service**
   ```bash
   systemctl enable cloudflared
   systemctl start cloudflared
   systemctl status cloudflared
   ```

#### Troubleshooting

```bash
# Check tunnel status
cloudflared tunnel list

# View logs
journalctl -u cloudflared -f

# Test configuration
cloudflared tunnel --config /etc/cloudflared/config.yml run
```

### 🐧 Debian Virtual Machine

**Purpose**: General-purpose Linux virtual machine for applications and development

#### Prerequisites

```bash
# Debian ISO or cloud template required
# Check available ISOs
qm list
```

#### Deployment Steps

1. **Deploy VM**

   - Service Type: `vm/debian`
   - Action: `apply`

2. **Default Configuration**

   - IP: `192.168.1.200/24` (static)
   - User: `debian`
   - Memory: 2048 MB
   - CPU: 2 cores
   - Disk: 20G

3. **Access VM**

   ```bash
   # SSH access (if cloud-init template used)
   ssh debian@192.168.1.200

   # Or use Proxmox console
   # Proxmox → VM → Console
   ```

4. **Initial Setup**

   ```bash
   # Update system
   sudo apt update && sudo apt upgrade -y

   # Install additional packages
   sudo apt install htop git curl wget
   ```

#### Custom Applications

Add setup script for automated application installation:

```bash
# Create setup script
cat > instances/prod/vm/debian/scripts/app-setup.sh << 'EOF'
#!/bin/bash
echo "Installing custom applications..."

# Docker installation
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

echo "Setup completed!"
EOF

# Reference in terraform.tfvars.example
setup_script = "./scripts/app-setup.sh"
enable_provisioning = true
```

### 🪟 Windows Tiny10 VM

**Purpose**: Lightweight Windows 10 virtual machine

#### Prerequisites

```bash
# Windows Tiny10 ISO required
# Upload to Proxmox storage
```

#### Deployment Steps

1. **Deploy VM**

   - Service Type: `vm/windows_tiny10`
   - Action: `apply`

2. **Configuration**

   - Memory: 4096 MB (minimum for Windows)
   - CPU: 2 cores
   - Disk: 40G
   - Network: DHCP (default)

3. **Manual Setup Required**

   ```
   Note: Windows VMs require manual setup after deployment
   - Boot from ISO
   - Install Windows
   - Configure network
   - Enable RDP (optional)
   ```

4. **Access VM**
   - Use Proxmox console for initial setup
   - RDP after network configuration
   - Find IP: Check Proxmox or DHCP server logs

#### Windows Configuration

```powershell
# Enable RDP (run as Administrator)
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

# Install Chocolatey (package manager)
Set-ExecutionPolicy Bypass -Scope Process -Force
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Install common tools
choco install googlechrome firefox vlc 7zip
```

## 🔄 Multi-Service Deployment

### Deploy Multiple Services

For complex setups, deploy services in order:

1. **Infrastructure Services First**

   ```bash
   # Deploy proxy manager first
   # Service: lxc/nginx_proxy_manager

   # Then tunnel
   # Service: lxc/cloudflare_tunnel
   ```

2. **Application Services**

   ```bash
   # Deploy application VMs
   # Service: vm/debian
   ```

3. **Configure Integration**
   - Set up proxy rules in Nginx Proxy Manager
   - Configure tunnel endpoints in Cloudflare

### Example Full Stack

```yaml
Architecture: Internet → Cloudflare → Cloudflare Tunnel → Nginx Proxy Manager → Application VMs

Services: 1. nginx_proxy_manager (192.168.1.100) - Reverse proxy
  2. cloudflare_tunnel (192.168.1.110) - Secure tunnel
  3. debian (192.168.1.200) - Application server
  4. Additional VMs as needed
```

## 🔍 Monitoring & Maintenance

### Health Checks

```bash
# Check all services
for ip in 192.168.1.100 192.168.1.110 192.168.1.200; do
  echo "Checking $ip..."
  ping -c 3 $ip
done

# Check specific services
curl -I http://192.168.1.100:81  # Nginx Proxy Manager
ssh debian@192.168.1.200 'uptime'  # Debian VM status
```

### Log Monitoring

```bash
# Cloudflare Tunnel logs
ssh root@192.168.1.110 'journalctl -u cloudflared -f'

# Nginx Proxy Manager logs
ssh root@192.168.1.100 'docker logs nginx-proxy-manager'

# System logs
ssh debian@192.168.1.200 'sudo journalctl -f'
```

### Updates

```bash
# Update containers
ssh root@container_ip 'apt update && apt upgrade -y'

# Update VMs
ssh user@vm_ip 'sudo apt update && sudo apt upgrade -y'

# Update Docker services
ssh root@192.168.1.100 'cd /opt/nginx-proxy-manager && docker-compose pull && docker-compose up -d'
```

## 🛠️ Troubleshooting

### Common Issues

#### Service Won't Start

```bash
# Check Terraform state
terraform show

# Check Proxmox logs
tail -f /var/log/pveproxy/access.log

# Verify network connectivity
ping proxmox_ip
```

#### Network Issues

```bash
# Check Proxmox bridges
ip link show

# Verify DHCP/static assignment
ip route show

# Check firewall
iptables -L
```

#### Authentication Problems

```bash
# Test API access
curl -k "https://proxmox:8006/api2/json/version" \
  -H "Authorization: PVEAPIToken=terraform@pam!terraform=your-token"
```

### Getting Help

1. **Check Logs**: Always check relevant log files first
2. **Validate Configuration**: Run `./validate-all.sh`
3. **Test Connectivity**: Verify network connectivity
4. **Review Documentation**: Check service-specific docs
5. **GitHub Issues**: Create issue with full error details

## 📚 Additional Resources

- [Proxmox VE Administration Guide](https://pve.proxmox.com/pve-docs/pve-admin-guide.html)
- [Cloudflare Tunnel Documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)
- [Nginx Proxy Manager Documentation](https://nginxproxymanager.com/guide/)
- [Terraform Proxmox Provider](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs)
