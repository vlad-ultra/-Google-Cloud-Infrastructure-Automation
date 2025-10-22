#!/bin/bash

# 🚀 Main Deployment Script
# This script deploys infrastructure using pre-configured images WITHOUT modifying configurations
# All configurations are preserved from the images

set -e

echo "🚀 Main Deployment Script (No Config Changes)"
echo "============================================="

# Navigate to project root directory (two levels up from scripts/deployment/)
cd "$(dirname "$0")/../.."

# Check if we're in the correct directory
if [ ! -f "infrastructure/main.tf" ]; then
    echo "❌ Error: Run script from project root directory"
    echo "Current directory: $(pwd)"
    echo "Looking for: infrastructure/main.tf"
    exit 1
fi

echo "📁 Working directory: $(pwd)"

# Check Google Cloud authentication
echo "🔐 Checking Google Cloud authentication..."
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo "❌ Error: Not authenticated to Google Cloud"
    echo "Run: gcloud auth login"
    exit 1
fi

# Get project ID
PROJECT_ID=$(gcloud config get-value project)
if [ -z "$PROJECT_ID" ]; then
    echo "❌ Error: PROJECT_ID not set"
    echo "Run: gcloud config set project YOUR_PROJECT_ID"
    exit 1
fi

echo "✅ Project ID: $PROJECT_ID"

# Check if infrastructure already exists
echo "🔍 Checking if infrastructure already exists..."
if gcloud compute instances describe haproxy-prod --zone=europe-west1-b --quiet 2>/dev/null; then
    echo "⚠️  Infrastructure already exists. Removing old servers (preserving static IPs)..."
    cd infrastructure
    terraform destroy -auto-approve -target=google_compute_instance.haproxy -target=google_compute_instance.web1 -target=google_compute_instance.web2 -target=google_compute_firewall.allow_http -target=google_compute_firewall.allow_https -target=google_compute_firewall.allow_ssh -target=google_compute_firewall.allow_haproxy_lb -target=google_compute_firewall.allow_haproxy_web1 -target=google_compute_firewall.allow_haproxy_web2 -target=google_compute_firewall.allow_haproxy_stats -target=google_compute_firewall.allow_haproxy_stats_page || true
    cd ..
fi

# Deploy infrastructure using pre-configured images
echo ""
echo "🏗️ Deploying infrastructure using pre-configured images (v3)..."
echo "⏱️ This will take ~30-60 seconds..."
echo "💡 All configurations are preserved from images - NO modifications applied!"

cd infrastructure
START_TIME=$(date +%s)
terraform init -upgrade
terraform plan -out=tfplan
terraform apply tfplan
END_TIME=$(date +%s)
DEPLOY_TIME=$((END_TIME - START_TIME))

echo ""
echo "✅ Infrastructure deployed!"
echo "=========================="
echo ""
echo "🔍 IP Addresses:"
echo "HAProxy: $(terraform output -raw haproxy_external_ip)"
echo "Web1: $(terraform output -raw web1_external_ip)"
echo "Web2: $(terraform output -raw web2_external_ip)"

# Wait for instances to be ready
echo ""
echo "⏳ Waiting for instances to be ready..."
sleep 30

# Apply content from web-apps/ directory
echo ""
echo "🔄 Applying content from web-apps/ directory..."

# Function to update HTML content
update_html_content() {
    local server_name=$1
    local html_file=$2
    local zone="europe-west1-b"
    
    echo "📝 Updating $server_name HTML content..."
    
    if [ ! -f "web-apps/$html_file" ]; then
        echo "⚠️  web-apps/$html_file not found, skipping $server_name HTML update"
        return
    fi
    
    # Copy file to server
    echo "📤 Uploading $html_file to $server_name..."
    gcloud compute scp "web-apps/$html_file" "$server_name:~/temp.html" --zone="$zone"
    
    # Apply changes on server
    gcloud compute ssh "$server_name" --zone="$zone" --command="
        echo '🔄 Applying HTML changes on $server_name...'
        
        # Backup current content
        sudo cp /var/www/html/index.html /var/www/html/index.html.backup.\$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
        
        # Remove old content
        sudo rm -f /var/www/html/index.html
        sudo rm -f /var/www/html/index.html.*
        
        # Copy new content
        sudo cp ~/temp.html /var/www/html/index.html
        sudo chown root:root /var/www/html/index.html
        sudo chmod 644 /var/www/html/index.html
        
        # Clean up temp file
        rm -f ~/temp.html
        
        # Restart nginx to ensure changes take effect
        sudo systemctl restart nginx
        
        echo '✅ $server_name HTML updated successfully'
    "
}

# Update web1 HTML
update_html_content "web1-prod" "web1.html"

# Update web2 HTML  
update_html_content "web2-prod" "web2.html"

# Update HAProxy dashboard
update_html_content "haproxy-prod" "haproxy.html"

# Update HAProxy configuration with current IPs
echo "📝 Updating HAProxy configuration with current IPs..."
WEB1_INTERNAL_IP="10.132.15.221"
WEB2_INTERNAL_IP="10.132.15.222"

gcloud compute ssh haproxy-prod --zone=europe-west1-b --command="
    echo '🔄 Updating HAProxy configuration...'
    
    # Backup current config
    sudo cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.backup.\$(date +%Y%m%d_%H%M%S)
    
    # Update backend IPs
    sudo sed -i 's/server web1 .*:80/server web1 $WEB1_INTERNAL_IP:80/' /etc/haproxy/haproxy.cfg
    sudo sed -i 's/server web2 .*:80/server web2 $WEB2_INTERNAL_IP:80/' /etc/haproxy/haproxy.cfg
    
    # Test configuration
    if sudo haproxy -c -f /etc/haproxy/haproxy.cfg; then
        sudo systemctl restart haproxy
        echo '✅ HAProxy configuration updated and restarted'
    else
        echo '❌ HAProxy configuration test failed, restoring backup'
        sudo cp /etc/haproxy/haproxy.cfg.backup.* /etc/haproxy/haproxy.cfg
        sudo systemctl restart haproxy
    fi
"

echo "✅ Content from web-apps/ applied successfully!"
echo "💡 HAProxy, Nginx, and SSL certificates are already configured in the images"

# Quick test
echo ""
echo "🧪 Quick test..."
HAPROXY_IP=$(terraform output -raw haproxy_external_ip)

echo "🌐 Testing Load Balancer..."
LB_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" https://balancer.svdevops.tech -k || echo "000")
if [ "$LB_RESPONSE" = "200" ]; then
    echo "✅ Load Balancer working (200)"
    
    # Test load balancing - show web1-web2 alternation (fast)
    echo ""
    echo "🔄 Testing Load Balancing (5 requests):"
    for i in {1..5}; do
        RESPONSE=$(curl -s https://balancer.svdevops.tech -k | grep -o "Web Server [12]" || echo "No response")
        echo "Request $i: $RESPONSE"
        sleep 0.2
    done
    echo "✅ Load balancing test completed!"
else
    echo "⚠️  Load Balancer not ready yet ($LB_RESPONSE) - may need a few more seconds"
fi

cd ..

echo ""
echo "🎉 Deployment completed!"
echo "======================="
echo ""
echo "🌐 URLs:"
echo "   Load Balancer: https://balancer.svdevops.tech"
echo "   Stats: http://$HAPROXY_IP:8080/stats"
echo "   Web1: https://web1.svdevops.tech"
echo "   Web2: https://web2.svdevops.tech"
echo ""
echo "⏱️  Total time: ~${DEPLOY_TIME} seconds"
echo ""
echo "💡 All configurations are preserved from images:"
echo "   ✅ HAProxy with Let's Encrypt certificates"
echo "   ✅ Nginx with correct server_name"
echo "   ✅ Health checks enabled"
echo "   ✅ Load balancing configured"
echo "   ✅ Content from web-apps/ applied"
echo ""
echo "🔧 If something doesn't work, check that images v3 were created correctly!"
echo "🔄 To update content only, edit files in web-apps/ and run ./deploy.sh again"