#!/bin/bash

# 🗑️ Destroy Infrastructure Script
# This script destroys all infrastructure while preserving static IPs

set -e

echo "🗑️ Destroying Infrastructure (Preserving Static IPs)"
echo "=================================================="

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

# Destroy infrastructure (preserve static IPs)
echo ""
echo "🗑️ Destroying infrastructure (preserving static IPs)..."
echo "⏱️ This will take ~30 seconds..."

START_TIME=$(date +%s)
terraform init -upgrade
terraform destroy -auto-approve -target=google_compute_instance.haproxy -target=google_compute_instance.web1 -target=google_compute_instance.web2 -target=google_compute_address.haproxy_internal_ip -target=google_compute_address.web1_internal_ip -target=google_compute_address.web2_internal_ip -target=google_compute_firewall.allow_http -target=google_compute_firewall.allow_https -target=google_compute_firewall.allow_ssh -target=google_compute_firewall.allow_haproxy_stats || true
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
echo "- Ready for next deployment"
echo ""
echo "✅ Infrastructure ready for next deployment!"


