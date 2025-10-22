#!/bin/bash

# 🔧 Quick HAProxy Configuration Application
# This script applies HAProxy configuration to existing servers

set -e

echo "🔧 Quick HAProxy Configuration Application"
echo "========================================="

# Navigate to project directory
cd "$(dirname "$0")"

# Check if we're in the correct directory
if [ ! -f "infrastructure/main.tf" ]; then
    echo "❌ Error: Run script from project root directory"
    exit 1
fi

echo "📁 Working directory: $(pwd)"

# Check if infrastructure exists
echo "🔍 Checking if infrastructure exists..."
if ! gcloud compute instances describe haproxy-prod --zone=europe-west1-b --quiet 2>/dev/null; then
    echo "❌ Error: Infrastructure not found. Run deploy.sh first."
    exit 1
fi

# Apply HAProxy configuration
echo "🔧 Applying HAProxy configuration with Let's Encrypt certificates..."
./scripts/configure-haproxy.sh

echo ""
echo "🎉 HAProxy configuration applied successfully!"
echo "🌐 https://balancer.svdevops.tech"
echo "📊 https://balancer.svdevops.tech/stats"
