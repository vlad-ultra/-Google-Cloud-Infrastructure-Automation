#!/bin/bash

# 🧪 Test New Images Script
# This script tests deployment with new images to ensure configurations are preserved

set -e

echo "🧪 Testing New Images with Preserved Configurations"
echo "=================================================="

# Navigate to project directory
cd "$(dirname "$0")"

# Check if we're in the correct directory
if [ ! -f "infrastructure/main.tf" ]; then
    echo "❌ Error: Run script from project root directory"
    exit 1
fi

echo "📁 Working directory: $(pwd)"

# Check if new images exist
echo "🔍 Checking if new images exist..."
if ! gcloud compute images describe haproxy-prod-image-v3 --quiet 2>/dev/null; then
    echo "❌ Error: New images not found. Run create-new-images.sh first."
    exit 1
fi

echo "✅ New images found"

# Destroy current infrastructure
echo ""
echo "🗑️ Destroying current infrastructure..."
./destroy-infrastructure.sh

# Wait a bit
echo "⏳ Waiting..."
sleep 10

# Deploy with new images
echo ""
echo "🚀 Deploying with new images..."
./test-deploy.sh

# Test configurations
echo ""
echo "🧪 Testing configurations..."

# Wait for instances to be ready
echo "⏳ Waiting for instances to be ready..."
sleep 30

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
echo "🎉 Test completed!"
echo "=================="
echo ""
echo "🌐 URLs:"
echo "   Load Balancer: https://balancer.svdevops.tech"
echo "   Stats: http://$HAPROXY_IP:8080/stats"
echo "   Web1: https://web1.svdevops.tech"
echo "   Web2: https://web2.svdevops.tech"
echo ""
echo "💡 If all tests pass, configurations are preserved in images!"
