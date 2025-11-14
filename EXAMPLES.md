# Configuration Examples

This document provides real-world configuration examples for different use cases and deployment scenarios.

## 🏠 Home Lab Setup

### Basic Home Infrastructure

**Scenario**: Home lab with web services, development environment, and secure remote access.

#### Network Plan

```
Network: 192.168.1.0/24
Gateway: 192.168.1.1
DNS: 192.168.1.1

Service IPs:
├── nginx_proxy_manager: 192.168.1.100
├── cloudflare_tunnel: 192.168.1.110
├── debian_dev: 192.168.1.200
└── windows_desktop: 192.168.1.210 (DHCP)
```

#### Service Configurations

**Nginx Proxy Manager** (`lxc/nginx_proxy_manager/terraform.tfvars`)

```hcl
# Proxmox Connection
proxmox_api_url          = "https://192.168.1.10:8006/api2/json"
proxmox_api_token_id     = "terraform@pam!terraform"
proxmox_api_token_secret = "your-secret-token"
proxmox_tls_insecure     = true

# Container Configuration
node = "pve"
hostname = "proxy-manager"
template = "local:vztmpl/debian-12-standard_12.2-1_amd64.tar.zst"
password = "secure-proxy-password"
ip = "192.168.1.100/24"
gateway = "192.168.1.1"
memory = 2048    # Increased for multiple proxies
cores = 2
disk_size = "15G"  # Extra space for logs
setup_script = "./scripts/nginx-proxy-setup.sh"
enable_provisioning = true
```

**Development VM** (`vm/debian/terraform.tfvars`)

```hcl
# Proxmox Connection
proxmox_api_url          = "https://192.168.1.10:8006/api2/json"
proxmox_api_token_id     = "terraform@pam!terraform"
proxmox_api_token_secret = "your-secret-token"
proxmox_tls_insecure     = true

# VM Configuration
node = "pve"
name = "debian-dev"
template = "local:iso/debian-12.2.0-amd64-netinst.iso"
cores = 4        # More CPU for development
memory = 8192    # 8GB RAM for development
storage = "local-lvm"
disk_size = "50G"  # Extra space for projects
bridge = "vmbr0"
ipconfig = "ip=192.168.1.200/24,gw=192.168.1.1"
user = "developer"
password = "dev-password"
ssh_keys = "ssh-rsa AAAAB3NzaC1yc2E... developer@laptop"
setup_script = "./scripts/dev-setup.sh"
enable_provisioning = true
```

#### Custom Development Setup Script

Create `vm/debian/scripts/dev-setup.sh`:

```bash
#!/bin/bash
echo "Setting up development environment..."

# Update system
apt-get update && apt-get upgrade -y

# Install development tools
apt-get install -y \
  git curl wget vim \
  build-essential \
  nodejs npm \
  python3 python3-pip \
  docker.io docker-compose \
  htop neofetch

# Configure Docker
usermod -aG docker developer
systemctl enable docker
systemctl start docker

# Install development languages
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt-get install -y nodejs

# Install Go
wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> /home/developer/.bashrc

# Install VS Code Server
curl -fsSL https://code-server.dev/install.sh | sh
systemctl enable --now code-server@developer

echo "Development environment setup completed!"
```

## 🏢 Small Business Setup

### Web Hosting with SSL and CDN

**Scenario**: Small business hosting multiple websites with automatic SSL certificates and global CDN.

#### Architecture

```
Internet → Cloudflare CDN → Cloudflare Tunnel → Nginx Proxy Manager → Web Servers
```

#### Production Web Server Configuration

**High-Performance Nginx Proxy** (`lxc/nginx_proxy_manager/terraform.tfvars`)

```hcl
# Production settings
node = "pve-prod-01"
hostname = "nginx-prod"
template = "local:vztmpl/debian-12-standard_12.2-1_amd64.tar.zst"
password = "strong-production-password"
ip = "10.0.1.100/24"
gateway = "10.0.1.1"
memory = 4096    # 4GB for high traffic
cores = 4        # 4 cores for SSL processing
disk_size = "30G"  # Space for logs and cache
setup_script = "./scripts/production-nginx-setup.sh"
enable_provisioning = true
```

**Production Nginx Setup Script**

```bash
#!/bin/bash
echo "Setting up production Nginx Proxy Manager..."

# System optimization
echo 'vm.swappiness=10' >> /etc/sysctl.conf
echo 'net.core.somaxconn=65535' >> /etc/sysctl.conf
sysctl -p

# Install Docker with production settings
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Docker daemon configuration
cat > /etc/docker/daemon.json << 'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

systemctl restart docker

# Production Nginx Proxy Manager with resource limits
mkdir -p /opt/nginx-proxy-manager
cd /opt/nginx-proxy-manager

cat > docker-compose.yml << 'EOF'
version: '3.8'
services:
  nginx-proxy-manager:
    image: 'jc21/nginx-proxy-manager:latest'
    restart: unless-stopped
    ports:
      - '80:80'
      - '81:81'
      - '443:443'
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt
    environment:
      DB_SQLITE_FILE: "/data/database.sqlite"
    deploy:
      resources:
        limits:
          memory: 2G
        reservations:
          memory: 1G
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:81"]
      interval: 30s
      timeout: 10s
      retries: 3
EOF

# Start services
docker-compose up -d

# Setup logrotate
cat > /etc/logrotate.d/nginx-proxy-manager << 'EOF'
/opt/nginx-proxy-manager/data/logs/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    postrotate
        docker-compose -f /opt/nginx-proxy-manager/docker-compose.yml restart
    endscript
}
EOF

echo "Production Nginx Proxy Manager setup completed!"
```

#### Application Server Configuration

**Web Application VM** (`vm/debian/terraform.tfvars`)

```hcl
# Production web server
node = "pve-prod-01"
name = "webapp-01"
template = "local:templates/debian-12-cloud"  # Cloud template for faster deployment
cores = 2
memory = 4096
storage = "ssd-storage"  # Fast storage for databases
disk_size = "40G"
bridge = "vmbr0"
ipconfig = "ip=10.0.1.201/24,gw=10.0.1.1"
user = "webapp"
password = "webapp-secure-password"
ssh_keys = "ssh-rsa AAAAB3NzaC1yc2E... deploy@cicd"
setup_script = "./scripts/webapp-setup.sh"
enable_provisioning = true
```

#### High-Availability Cloudflare Tunnel

**Cloudflare Tunnel Configuration** (`lxc/cloudflare_tunnel/terraform.tfvars`)

```hcl
# Production tunnel
node = "pve-prod-01"
hostname = "cf-tunnel-prod"
template = "local:vztmpl/debian-12-standard_12.2-1_amd64.tar.zst"
password = "tunnel-secure-password"
ip = "10.0.1.110/24"
gateway = "10.0.1.1"
memory = 1024
cores = 2
disk_size = "10G"
setup_script = "./scripts/production-tunnel-setup.sh"
enable_provisioning = true
```

## 🔬 Development & Testing Environment

### Multi-Service Development Stack

**Scenario**: Development environment with multiple interconnected services for testing microservices architecture.

#### Service Stack

```
Frontend (React) → API Gateway → Backend Services → Database
     ↓                ↓              ↓              ↓
   Port 3000      Port 8080     Port 8081-8084   Port 5432
```

#### Development VM with Multiple Services

**Full-Stack Development VM** (`vm/debian/terraform.tfvars`)

```hcl
# Development powerhouse
node = "pve-dev"
name = "dev-stack"
template = "local:templates/debian-12-cloud"
cores = 8        # High CPU for compilation
memory = 16384   # 16GB for multiple services
storage = "nvme-fast"
disk_size = "100G"  # Lots of space for projects
bridge = "vmbr1"     # Separate dev network
ipconfig = "ip=192.168.10.100/24,gw=192.168.10.1"
user = "developer"
password = "dev-environment-password"
ssh_keys = "ssh-rsa AAAAB3NzaC1yc2E... dev-team@company"
setup_script = "./scripts/full-stack-dev-setup.sh"
enable_provisioning = true
```

#### Comprehensive Development Setup

**Full-Stack Development Setup Script**

```bash
#!/bin/bash
echo "Setting up full-stack development environment..."

# Update system
apt-get update && apt-get upgrade -y

# Install base development tools
apt-get install -y \
  git curl wget vim neovim \
  build-essential \
  apt-transport-https \
  ca-certificates \
  gnupg \
  lsb-release

# Install Docker and Docker Compose
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker developer

# Install Node.js and npm
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# Install Python and pip
apt-get install -y python3 python3-pip python3-venv

# Install Go
GOLANG_VERSION="1.21.4"
wget https://go.dev/dl/go${GOLANG_VERSION}.linux-amd64.tar.gz
tar -C /usr/local -xzf go${GOLANG_VERSION}.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> /home/developer/.bashrc

# Install Rust
sudo -u developer curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Install databases
apt-get install -y postgresql postgresql-contrib redis-server

# Configure PostgreSQL
sudo -u postgres createuser --createdb developer
sudo -u postgres createdb -O developer devdb

# Install development databases with Docker
sudo -u developer mkdir -p /home/developer/docker-dev
cat > /home/developer/docker-dev/docker-compose.yml << 'EOF'
version: '3.8'
services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: devdb
      POSTGRES_USER: developer
      POSTGRES_PASSWORD: devpass
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

  mongodb:
    image: mongo:7
    environment:
      MONGO_INITDB_ROOT_USERNAME: developer
      MONGO_INITDB_ROOT_PASSWORD: devpass
    ports:
      - "27017:27017"
    volumes:
      - mongo_data:/data/db

volumes:
  postgres_data:
  redis_data:
  mongo_data:
EOF

# Install VS Code Server
curl -fsSL https://code-server.dev/install.sh | sh
sudo -u developer mkdir -p /home/developer/.config/code-server
cat > /home/developer/.config/code-server/config.yaml << 'EOF'
bind-addr: 0.0.0.0:8080
auth: password
password: dev-code-password
cert: false
EOF

systemctl enable --now code-server@developer

# Install development tools
npm install -g \
  @angular/cli \
  @vue/cli \
  create-react-app \
  typescript \
  ts-node \
  nodemon \
  pm2

# Install Python tools
pip3 install \
  fastapi \
  uvicorn \
  django \
  flask \
  sqlalchemy \
  alembic \
  pytest

echo "Full-stack development environment setup completed!"
echo "Access VS Code at: http://192.168.10.100:8080"
echo "Password: dev-code-password"
```

## 🌐 Multi-Site Hosting

### Multiple Domain Configuration

**Scenario**: Hosting multiple websites with different configurations and SSL certificates.

#### Nginx Proxy Manager Configuration for Multiple Sites

After deploying Nginx Proxy Manager, configure proxy hosts:

```yaml
# Site 1: Corporate Website
Proxy Host:
  Domain Names: corporate.example.com
  Forward Hostname/IP: 192.168.1.201
  Forward Port: 80
  SSL: Request Let's Encrypt Certificate
  Force SSL: Yes

# Site 2: Web Application
Proxy Host:
  Domain Names: app.example.com
  Forward Hostname/IP: 192.168.1.202
  Forward Port: 8080
  SSL: Request Let's Encrypt Certificate
  Force SSL: Yes

# Site 3: API Gateway
Proxy Host:
  Domain Names: api.example.com
  Forward Hostname/IP: 192.168.1.203
  Forward Port: 3000
  SSL: Request Let's Encrypt Certificate
  Force SSL: Yes
  Custom Locations:
    Location: /v1/
    Forward Hostname/IP: 192.168.1.204
    Forward Port: 8081
```

#### Cloudflare Tunnel Configuration for Multiple Sites

```yaml
# /etc/cloudflared/config.yml
tunnel: your-tunnel-id
credentials-file: /etc/cloudflared/your-tunnel-id.json

ingress:
  # Corporate website
  - hostname: corporate.example.com
    service: http://192.168.1.100:80

  # Web application
  - hostname: app.example.com
    service: http://192.168.1.100:80
    originRequest:
      httpHostHeader: app.example.com

  # API endpoints
  - hostname: api.example.com
    path: /v1/*
    service: http://192.168.1.100:80
    originRequest:
      httpHostHeader: api.example.com

  # Admin interface (restricted)
  - hostname: admin.example.com
    service: http://192.168.1.100:81
    originRequest:
      httpHostHeader: admin.example.com

  # Catch-all
  - service: http_status:404
```

## 📊 Monitoring & Observability Setup

### Monitoring Stack with Grafana

**Monitoring VM Configuration** (`vm/debian/terraform.tfvars`)

```hcl
# Monitoring server
node = "pve"
name = "monitoring"
template = "local:templates/debian-12-cloud"
cores = 4
memory = 8192
storage = "local-lvm"
disk_size = "80G"  # Space for metrics storage
bridge = "vmbr0"
ipconfig = "ip=192.168.1.250/24,gw=192.168.1.1"
user = "monitor"
password = "monitoring-password"
setup_script = "./scripts/monitoring-setup.sh"
enable_provisioning = true
```

**Monitoring Setup Script**

```bash
#!/bin/bash
echo "Setting up monitoring stack..."

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Create monitoring stack
mkdir -p /opt/monitoring/{grafana,prometheus,alertmanager}
cd /opt/monitoring

cat > docker-compose.yml << 'EOF'
version: '3.8'
services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus:/etc/prometheus
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    volumes:
      - grafana_data:/var/lib/grafana
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin123

  node_exporter:
    image: prom/node-exporter:latest
    container_name: node_exporter
    ports:
      - "9100:9100"
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.rootfs=/rootfs'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'

volumes:
  prometheus_data:
  grafana_data:
EOF

# Start monitoring stack
docker-compose up -d

echo "Monitoring stack setup completed!"
echo "Grafana: http://192.168.1.250:3000 (admin/admin123)"
echo "Prometheus: http://192.168.1.250:9090"
```

These examples provide practical, real-world configurations that you can adapt for your specific use cases. Each configuration includes resource sizing recommendations and custom setup scripts tailored to the intended use case.
