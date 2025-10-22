#!/bin/bash

# 🔧 HAProxy Configuration Script
# This script applies the correct HAProxy configuration with Let's Encrypt certificates

set -e

echo "🔧 Configuring HAProxy with Let's Encrypt certificates..."

# Get HAProxy instance name from Terraform output
HAPROXY_INSTANCE=$(cd infrastructure && terraform output -raw haproxy_instance_name 2>/dev/null || echo "haproxy-prod")
HAPROXY_ZONE=$(cd infrastructure && terraform output -raw haproxy_zone 2>/dev/null || echo "europe-west1-b")

echo "📋 HAProxy instance: $HAPROXY_INSTANCE"
echo "📋 HAProxy zone: $HAPROXY_ZONE"

# Wait for instance to be ready
echo "⏳ Waiting for HAProxy instance to be ready..."
sleep 10

# Stop Nginx on HAProxy instance (if running)
echo "🛑 Stopping Nginx on HAProxy instance..."
gcloud compute ssh $HAPROXY_INSTANCE --zone=$HAPROXY_ZONE --command="sudo systemctl stop nginx 2>/dev/null || true"

# Upload HAProxy configuration
echo "📤 Uploading HAProxy configuration..."
gcloud compute scp infrastructure/haproxy-config.cfg $HAPROXY_INSTANCE:/tmp/haproxy.cfg --zone=$HAPROXY_ZONE

# Apply configuration
echo "⚙️ Applying HAProxy configuration..."
gcloud compute ssh $HAPROXY_INSTANCE --zone=$HAPROXY_ZONE --command="
    sudo cp /tmp/haproxy.cfg /etc/haproxy/haproxy.cfg
    sudo chown haproxy:haproxy /etc/haproxy/haproxy.cfg
    sudo chmod 644 /etc/haproxy/haproxy.cfg
    sudo systemctl restart haproxy
    sudo systemctl status haproxy --no-pager
"

# Test configuration
echo "🧪 Testing HAProxy configuration..."
sleep 5

# Test HTTP redirect
echo "📡 Testing HTTP redirect..."
HTTP_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://$(cd infrastructure && terraform output -raw haproxy_external_ip) || echo "000")
if [ "$HTTP_RESPONSE" = "301" ]; then
    echo "✅ HTTP redirect working (301)"
else
    echo "❌ HTTP redirect failed ($HTTP_RESPONSE)"
fi

# Test HTTPS
echo "📡 Testing HTTPS..."
HTTPS_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" https://$(cd infrastructure && terraform output -raw haproxy_external_ip) -k || echo "000")
if [ "$HTTPS_RESPONSE" = "200" ]; then
    echo "✅ HTTPS working (200)"
else
    echo "❌ HTTPS failed ($HTTPS_RESPONSE)"
fi

# Test stats on port 8080
echo "📡 Testing stats page on port 8080..."
STATS_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://$(cd infrastructure && terraform output -raw haproxy_external_ip):8080/stats || echo "000")
if [ "$STATS_RESPONSE" = "200" ]; then
    echo "✅ Stats page on port 8080 working (200)"
else
    echo "❌ Stats page on port 8080 failed ($STATS_RESPONSE)"
fi

# Test stats on port 8084
echo "📡 Testing stats page on port 8084..."
STATS_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://$(cd infrastructure && terraform output -raw haproxy_external_ip):8084/stats || echo "000")
if [ "$STATS_RESPONSE" = "200" ]; then
    echo "✅ Stats page on port 8084 working (200)"
else
    echo "❌ Stats page on port 8084 failed ($STATS_RESPONSE)"
fi

echo ""
echo "🎉 HAProxy configuration completed!"
echo "🌐 Load Balancer: https://balancer.svdevops.tech"
echo "📊 Stats: http://$(cd infrastructure && terraform output -raw haproxy_external_ip):8080/stats"
echo "📊 Stats (backup): http://$(cd infrastructure && terraform output -raw haproxy_external_ip):8084/stats"
