#!/bin/bash
set -e

echo "Starting production web server setup..."

# Install Nginx
apt-get install -y nginx

# Enable and start Nginx
systemctl enable nginx
systemctl start nginx

# Configure firewall (if ufw is installed)
if command -v ufw &> /dev/null; then
    ufw allow 80/tcp
    ufw allow 443/tcp
fi

echo "Web server setup completed!"
