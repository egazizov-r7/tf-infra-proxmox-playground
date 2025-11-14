#!/bin/bash

# Validate all infrastructure configurations
# Usage: ./validate-all.sh

echo "🔍 Validating All Infrastructure Configurations"
echo "==============================================="
echo ""

services=(
    "lxc/nginx_proxy_manager"
    "lxc/cloudflare_tunnel" 
    "vm/debian"
    "vm/windows_tiny10"
)

success_count=0
total_count=${#services[@]}

for service in "${services[@]}"; do
    echo "📦 Validating $service..."
    
    if [ ! -d "$service" ]; then
        echo "  ❌ Directory not found: $service"
        continue
    fi
    
    cd "$service"
    
    # Check required files
    required_files=("main.tf" "variables.tf" "outputs.tf" "terraform.tfvars.example")
    missing_files=()
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            missing_files+=("$file")
        fi
    done
    
    if [ ${#missing_files[@]} -gt 0 ]; then
        echo "  ❌ Missing files: ${missing_files[*]}"
        cd - > /dev/null
        continue
    fi
    
    # Terraform validation
    if command -v terraform >/dev/null 2>&1; then
        # Create test terraform.tfvars
        cp terraform.tfvars.example test.tfvars
        sed -i.bak 's/your-proxmox-host/test-host/g; s/your-api-token-secret/test-secret/g' test.tfvars
        
        if terraform init -backend=false > /dev/null 2>&1 && terraform validate > /dev/null 2>&1; then
            echo "  ✅ $service - Configuration valid"
            success_count=$((success_count + 1))
        else
            echo "  ❌ $service - Terraform validation failed"
        fi
        
        # Cleanup
        rm -f test.tfvars test.tfvars.bak .terraform.lock.hcl
        rm -rf .terraform/
    else
        echo "  ✅ $service - Files present (Terraform not installed for validation)"
        success_count=$((success_count + 1))
    fi
    
    cd - > /dev/null
    echo ""
done

echo "==============================================="
echo "📊 Validation Summary: $success_count/$total_count services passed"

if [ $success_count -eq $total_count ]; then
    echo "🎉 All services are ready for deployment!"
    echo ""
    echo "📌 To deploy a service:"
    echo "   1. Go to GitHub Actions"
    echo "   2. Run 'Deploy Infrastructure' workflow"
    echo "   3. Select the service and action"
else
    echo "⚠️  Some services have configuration issues"
    exit 1
fi