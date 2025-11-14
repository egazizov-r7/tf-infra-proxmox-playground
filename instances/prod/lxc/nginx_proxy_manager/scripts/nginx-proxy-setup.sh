#!/bin/bash
# Nginx Proxy Manager Setup Script

echo "Starting Nginx Proxy Manager setup..."

# Update system
apt-get update
apt-get upgrade -y

# Install dependencies
apt-get install -y curl wget git python3 python3-pip

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
systemctl enable docker
systemctl start docker

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create directory for Nginx Proxy Manager
mkdir -p /opt/nginx-proxy-manager
cd /opt/nginx-proxy-manager

# Create docker-compose.yml
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
EOF

# Start Nginx Proxy Manager
docker-compose up -d

# Create systemd service
cat > /etc/systemd/system/nginx-proxy-manager.service << 'EOF'
[Unit]
Description=Nginx Proxy Manager
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/nginx-proxy-manager
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down

[Install]
WantedBy=multi-user.target
EOF

systemctl enable nginx-proxy-manager
systemctl start nginx-proxy-manager

echo "Nginx Proxy Manager setup completed!"
echo "Access the admin interface at: http://$(hostname -I | awk '{print $1}'):81"
echo "Default credentials: admin@example.com / changeme"