#!/bin/bash

# ⚡ Ultra-Fast Deployment with Pre-configured Images
# This script deploys infrastructure using pre-configured images WITHOUT modifying configurations
# All configurations are preserved from the images

set -e

echo "⚡ Ultra-Fast Deployment with Pre-configured Images"
echo "================================================="

# Navigate to project directory
cd "$(dirname "$0")"

# Check if we're in the correct directory
if [ ! -f "infrastructure/main.tf" ]; then
    echo "❌ Error: Run script from project root directory"
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

# Navigate to infrastructure directory
cd infrastructure

# Deploy infrastructure using pre-configured images
echo ""
echo "🚀 Deploying infrastructure with pre-configured images (v3)..."
echo "⏱️ This will take ~30-60 seconds..."
echo "💡 All configurations are preserved from images - NO modifications applied!"

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

# NO configuration changes - everything is set as default in images
echo ""
echo "✅ No configuration changes applied - using default configurations from images"
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
echo "🎉 Ultra-fast deployment completed!"
echo "=================================="
echo ""
echo "🌐 URLs:"
echo "   Load Balancer: https://balancer.svdevops.tech"
echo "   Stats: http://$HAPROXY_IP:8080/stats"
echo "   Web1: https://web1.svdevops.tech"
echo "   Web2: https://web2.svdevops.tech"
echo ""
echo "⏱️  Total time: ~${DEPLOY_TIME} seconds (with pre-configured images)"
echo ""
echo "💡 All configurations are preserved from images:"
echo "   ✅ HAProxy with Let's Encrypt certificates"
echo "   ✅ Nginx with correct server_name"
echo "   ✅ Health checks enabled"
echo "   ✅ Load balancing configured"
echo ""
echo "🔧 If something doesn't work, check that images v3 were created correctly!"