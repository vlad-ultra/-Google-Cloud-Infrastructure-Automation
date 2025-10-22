#!/bin/bash

# 🔄 Load Balancing Test Script (Fast)
# This script tests load balancing by making multiple requests and showing the alternation

set -e

echo "🔄 Load Balancing Test (Fast)"
echo "============================="

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

echo "✅ Infrastructure found"

# Test Load Balancer basic connectivity
echo ""
echo "🌐 Testing Load Balancer connectivity..."
LB_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" https://balancer.svdevops.tech -k || echo "000")
if [ "$LB_RESPONSE" != "200" ]; then
    echo "❌ Load Balancer not responding ($LB_RESPONSE)"
    exit 1
fi

echo "✅ Load Balancer is responding"

# Test load balancing with fast output
echo ""
echo "🔄 Testing Load Balancing (10 requests):"
echo "========================================"

WEB1_COUNT=0
WEB2_COUNT=0

for i in {1..10}; do
    RESPONSE=$(curl -s https://balancer.svdevops.tech -k | grep -o "Web Server [12]" || echo "No response")
    
    if [[ "$RESPONSE" == *"Server 1"* ]]; then
        WEB1_COUNT=$((WEB1_COUNT + 1))
        echo "Request $i: $RESPONSE"
    elif [[ "$RESPONSE" == *"Server 2"* ]]; then
        WEB2_COUNT=$((WEB2_COUNT + 1))
        echo "Request $i: $RESPONSE"
    else
        echo "Request $i: No response"
    fi
    
    sleep 0.1
done

echo "========================================"
echo "📊 Load Balancing Statistics:"
echo "   Web1 responses: $WEB1_COUNT"
echo "   Web2 responses: $WEB2_COUNT"

# Check if balancing is working
if [ $WEB1_COUNT -gt 0 ] && [ $WEB2_COUNT -gt 0 ]; then
    echo "✅ Load balancing is working correctly!"
else
    echo "❌ Load balancing may not be working correctly"
fi

echo ""
echo "🎉 Load balancing test completed!"
echo "================================"
echo ""
echo "🌐 URLs:"
echo "   Load Balancer: https://balancer.svdevops.tech"
echo "   Web1: https://web1.svdevops.tech"
echo "   Web2: https://web2.svdevops.tech"