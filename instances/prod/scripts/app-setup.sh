#!/bin/bash
set -e

echo "Starting production app server setup..."

# Install Docker
apt-get install -y docker.io docker-compose

# Enable and start Docker
systemctl enable docker
systemctl start docker

# Add user to docker group
usermod -aG docker $SUDO_USER || true

echo "App server setup completed!"
