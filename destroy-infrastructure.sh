#!/bin/bash

# 🗑️ Destroy Infrastructure Script (Preserving Images)
# This script destroys infrastructure while preserving static IPs and custom images

set -e

echo "🗑️ Destroying Infrastructure (Preserving Static IPs & Images)"
echo "============================================================"

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

# Destroy infrastructure (preserve static IPs and images)
echo ""
echo "🗑️ Destroying infrastructure (preserving static IPs & images)..."
echo "⏱️ This will take ~30 seconds..."

START_TIME=$(date +%s)
terraform init -upgrade
terraform destroy -auto-approve -target=google_compute_instance.haproxy -target=google_compute_instance.web1 -target=google_compute_instance.web2 -target=google_compute_firewall.allow_http -target=google_compute_firewall.allow_https -target=google_compute_firewall.allow_ssh -target=google_compute_firewall.allow_haproxy_lb -target=google_compute_firewall.allow_haproxy_web1 -target=google_compute_firewall.allow_haproxy_web2 -target=google_compute_firewall.allow_haproxy_stats -target=google_compute_firewall.allow_haproxy_stats_page || true
END_TIME=$(date +%s)
DESTROY_TIME=$((END_TIME - START_TIME))

echo ""
echo "🎉 Infrastructure destroyed successfully!"
echo "======================================="
echo ""
echo "⏱️ Total destroy time: ${DESTROY_TIME} seconds"
echo ""
echo "💰 Cost Savings:"
echo "- All compute instances destroyed"
echo "- Static IPs preserved (no additional cost)"
echo "- Custom images preserved (for fast deployment)"
echo "- Ready for next deployment"
echo ""
echo "✅ Infrastructure ready for next deployment!"
echo ""
echo "🖼️ Preserved images:"
echo "   - haproxy-prod-image-v3"
echo "   - web1-prod-image-v3" 
echo "   - web2-prod-image-v3"
echo ""
echo "🚀 Next deployment will be ultra-fast using preserved images!"

