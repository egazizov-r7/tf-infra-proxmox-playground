#!/bin/bash
set -e

echo "Starting production database setup..."

# Install PostgreSQL
apt-get install -y postgresql postgresql-contrib

# Enable and start PostgreSQL
systemctl enable postgresql
systemctl start postgresql

echo "Database setup completed!"
