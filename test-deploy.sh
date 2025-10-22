#!/bin/bash

# 🧪 Test Deployment Script
# This script deploys infrastructure using pre-configured images WITHOUT modifying configurations
# Perfect for testing - uses existing configurations from images

set -e

echo "🧪 Test Deployment (No Config Changes)"
echo "====================================="

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
echo "🏗️ Deploying infrastructure using pre-configured images..."
echo "⏱️ This will take ~30-60 seconds..."

cd infrastructure
START_TIME=$(date +%s)
terraform init -upgrade
terraform plan -out=tfplan
terraform apply tfplan
END_TIME=$(date +%s)
DEPLOY_TIME=$((END_TIME - START_TIME))

echo ""
echo "✅ Infrastructure deployed!"
echo "🔍 IP Addresses:"
echo "HAProxy: $(terraform output -raw haproxy_external_ip)"
echo "Web1: $(terraform output -raw web1_external_ip)"
echo "Web2: $(terraform output -raw web2_external_ip)"

# Wait for instances to be ready
echo ""
echo "⏳ Waiting for instances to be ready..."
sleep 30

# Quick test WITHOUT modifying configurations
echo ""
echo "🧪 Testing existing configurations..."

# Test HAProxy
echo "📡 Testing HAProxy..."
HAPROXY_IP=$(terraform output -raw haproxy_external_ip)
HTTP_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://$HAPROXY_IP || echo "000")
HTTPS_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" https://$HAPROXY_IP -k || echo "000")
STATS_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://$HAPROXY_IP:8084/stats || echo "000")

echo "   HTTP: $HTTP_RESPONSE"
echo "   HTTPS: $HTTPS_RESPONSE"
echo "   Stats: $STATS_RESPONSE"

# Test Web Servers
echo "📡 Testing Web Servers..."
WEB1_IP=$(terraform output -raw web1_external_ip)
WEB2_IP=$(terraform output -raw web2_external_ip)

WEB1_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://$WEB1_IP || echo "000")
WEB2_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://$WEB2_IP || echo "000")

echo "   Web1: $WEB1_RESPONSE"
echo "   Web2: $WEB2_RESPONSE"

# Test Domains
echo "📡 Testing Domains..."
DOMAIN_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" https://balancer.svdevops.tech -k || echo "000")
echo "   balancer.svdevops.tech: $DOMAIN_RESPONSE"

echo ""
echo "🎉 Test deployment completed!"
echo "============================="
echo ""
echo "⏱️  Total time: ${DEPLOY_TIME} seconds"
echo ""
echo "🌐 URLs:"
echo "   Load Balancer: https://balancer.svdevops.tech"
echo "   Stats: http://$HAPROXY_IP:8084/stats"
echo "   Web1: https://web1.svdevops.tech"
echo "   Web2: https://web2.svdevops.tech"
echo ""
echo "💡 Note: Using existing configurations from images"
echo "   - No HAProxy configuration changes"
echo "   - No Nginx configuration changes"
echo "   - Perfect for testing current setup"
echo ""
echo "🔧 To apply custom configurations, run:"
echo "   ./apply-haproxy-config.sh"
