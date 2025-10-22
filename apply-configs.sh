#!/bin/bash

# 🔧 Apply Configurations Script
# This script applies configurations to existing instances (only when needed)
# Use this ONLY if you need to update configurations after deployment

set -e

echo "🔧 Apply Configurations Script"
echo "============================="

# Navigate to project directory
cd "$(dirname "$0")"

# Check if we're in the correct directory
if [ ! -f "infrastructure/main.tf" ]; then
    echo "❌ Error: Run script from project root directory"
    exit 1
fi

echo "📁 Working directory: $(pwd)"

# Check if instances exist
echo "🔍 Checking if instances exist..."
if ! gcloud compute instances describe haproxy-prod --zone=europe-west1-b --quiet 2>/dev/null; then
    echo "❌ Error: Instances not found. Run deploy.sh first."
    exit 1
fi

echo "✅ Instances found"

# Apply HAProxy configuration
echo ""
echo "🔧 Applying HAProxy configuration..."
./scripts/configure-haproxy.sh

# Update content on web servers
echo ""
echo "📝 Updating content on web servers..."
./update-content.sh

# Test configurations
echo ""
echo "🧪 Testing configurations..."

# Wait for configurations to be applied
echo "⏳ Waiting for configurations to be applied..."
sleep 10

# Test HAProxy stats
echo "📊 Testing HAProxy stats..."
HAPROXY_IP=$(cd infrastructure && terraform output -raw haproxy_external_ip)
STATS_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://$HAPROXY_IP:8080/stats || echo "000")
if [ "$STATS_RESPONSE" = "200" ]; then
    echo "✅ HAProxy stats working (200)"
else
    echo "❌ HAProxy stats failed ($STATS_RESPONSE)"
fi

# Test Load Balancer
echo "🌐 Testing Load Balancer..."
LB_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" https://balancer.svdevops.tech -k || echo "000")
if [ "$LB_RESPONSE" = "200" ]; then
    echo "✅ Load Balancer working (200)"
else
    echo "❌ Load Balancer failed ($LB_RESPONSE)"
fi

# Test Web Servers
echo "🖥️ Testing Web Servers..."
WEB1_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" https://web1.svdevops.tech -k || echo "000")
WEB2_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" https://web2.svdevops.tech -k || echo "000")

if [ "$WEB1_RESPONSE" = "200" ]; then
    echo "✅ Web1 working (200)"
else
    echo "❌ Web1 failed ($WEB1_RESPONSE)"
fi

if [ "$WEB2_RESPONSE" = "200" ]; then
    echo "✅ Web2 working (200)"
else
    echo "❌ Web2 failed ($WEB2_RESPONSE)"
fi

echo ""
echo "🎉 Configurations applied successfully!"
echo "====================================="
echo ""
echo "🌐 URLs:"
echo "   Load Balancer: https://balancer.svdevops.tech"
echo "   Stats: http://$HAPROXY_IP:8080/stats"
echo "   Web1: https://web1.svdevops.tech"
echo "   Web2: https://web2.svdevops.tech"
echo ""
echo "💡 Use this script ONLY when you need to update configurations!"
echo "   For normal deployment, use deploy.sh (no config changes)"
