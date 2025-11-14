# Production Environment Example

This is a template for production infrastructure. Copy from dev and customize.

## Setup

```bash
cd instances/prod
cp terraform.tfvars.example terraform.tfvars
# Edit with production values
terraform init
terraform apply
```

## Configuration

Use more robust settings for production:

- Larger resource allocations
- Static IPs (not DHCP)
- Backup-enabled storage
- Multiple redundant instances
- Monitoring and logging setup
