#!/bin/bash
# Cloudflare Tunnel Setup Script

echo "Starting Cloudflare Tunnel setup..."

# Update system
apt-get update
apt-get upgrade -y

# Install dependencies
apt-get install -y curl wget

# Download and install cloudflared
curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
dpkg -i cloudflared.deb

# Create cloudflared user
useradd -r -s /bin/false cloudflared

# Create directories
mkdir -p /etc/cloudflared
mkdir -p /var/log/cloudflared
chown cloudflared:cloudflared /etc/cloudflared
chown cloudflared:cloudflared /var/log/cloudflared

# Create basic configuration template
cat > /etc/cloudflared/config.yml << 'EOF'
# Cloudflare Tunnel Configuration
# This is a template - you need to configure it with your tunnel details

tunnel: YOUR_TUNNEL_ID
credentials-file: /etc/cloudflared/YOUR_TUNNEL_ID.json

# Example ingress rules
ingress:
  # Catch-all rule (must be last)
  - service: http_status:404
EOF

# Create systemd service
cat > /etc/systemd/system/cloudflared.service << 'EOF'
[Unit]
Description=Cloudflare Tunnel
After=network.target

[Service]
Type=simple
User=cloudflared
Group=cloudflared
ExecStart=/usr/local/bin/cloudflared tunnel --config /etc/cloudflared/config.yml run
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

# Set permissions
chown root:root /etc/systemd/system/cloudflared.service
chmod 644 /etc/systemd/system/cloudflared.service

# Reload systemd but don't start yet (needs configuration)
systemctl daemon-reload

echo "Cloudflare Tunnel setup completed!"
echo ""
echo "⚠️  CONFIGURATION REQUIRED:"
echo "1. Create a tunnel in Cloudflare Dashboard"
echo "2. Download the credentials file to /etc/cloudflared/"
echo "3. Update /etc/cloudflared/config.yml with your tunnel details"
echo "4. Start the service: systemctl enable --now cloudflared"