#!/bin/bash

# 🔧 Restore Configurations Script
# This script restores configurations from backups/current-state to servers

set -e

echo "🔧 Restore Configurations from Backups"
echo "====================================="

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

# Get instance details
HAPROXY_INSTANCE="haproxy-prod"
WEB1_INSTANCE="web1-prod"
WEB2_INSTANCE="web2-prod"
ZONE="europe-west1-b"

# Restore HAProxy configuration
echo ""
echo "🔧 Restoring HAProxy configuration..."
if [ -f "backups/current-state/haproxy.cfg" ]; then
    echo "📤 Uploading HAProxy configuration..."
    gcloud compute scp backups/current-state/haproxy.cfg $HAPROXY_INSTANCE:/tmp/haproxy.cfg --zone=$ZONE
    
    echo "⚙️ Applying HAProxy configuration..."
    gcloud compute ssh $HAPROXY_INSTANCE --zone=$ZONE --command="
        sudo cp /tmp/haproxy.cfg /etc/haproxy/haproxy.cfg
        sudo chown haproxy:haproxy /etc/haproxy/haproxy.cfg
        sudo chmod 644 /etc/haproxy/haproxy.cfg
        sudo systemctl restart haproxy
        sudo systemctl status haproxy --no-pager
        rm -f /tmp/haproxy.cfg
    "
    echo "✅ HAProxy configuration restored"
else
    echo "❌ HAProxy configuration file not found in backups/current-state/"
fi

# Restore Web1 Nginx configuration
echo ""
echo "🔧 Restoring Web1 Nginx configuration..."
if [ -f "backups/current-state/web1-nginx.conf" ]; then
    echo "📤 Uploading Web1 Nginx configuration..."
    gcloud compute scp backups/current-state/web1-nginx.conf $WEB1_INSTANCE:/tmp/default --zone=$ZONE
    
    echo "⚙️ Applying Web1 Nginx configuration..."
    gcloud compute ssh $WEB1_INSTANCE --zone=$ZONE --command="
        sudo cp /tmp/default /etc/nginx/sites-available/default
        sudo chown root:root /etc/nginx/sites-available/default
        sudo chmod 644 /etc/nginx/sites-available/default
        sudo nginx -t
        sudo systemctl reload nginx
        sudo systemctl status nginx --no-pager
        rm -f /tmp/default
    "
    echo "✅ Web1 Nginx configuration restored"
else
    echo "❌ Web1 Nginx configuration file not found in backups/current-state/"
fi

# Restore Web2 Nginx configuration
echo ""
echo "🔧 Restoring Web2 Nginx configuration..."
if [ -f "backups/current-state/web2-nginx.conf" ]; then
    echo "📤 Uploading Web2 Nginx configuration..."
    gcloud compute scp backups/current-state/web2-nginx.conf $WEB2_INSTANCE:/tmp/default --zone=$ZONE
    
    echo "⚙️ Applying Web2 Nginx configuration..."
    gcloud compute ssh $WEB2_INSTANCE --zone=$ZONE --command="
        sudo cp /tmp/default /etc/nginx/sites-available/default
        sudo chown root:root /etc/nginx/sites-available/default
        sudo chmod 644 /etc/nginx/sites-available/default
        sudo nginx -t
        sudo systemctl reload nginx
        sudo systemctl status nginx --no-pager
        rm -f /tmp/default
    "
    echo "✅ Web2 Nginx configuration restored"
else
    echo "❌ Web2 Nginx configuration file not found in backups/current-state/"
fi

# Test configurations
echo ""
echo "🧪 Testing restored configurations..."

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
echo "🎉 Configurations restored successfully!"
echo "======================================"
echo ""
echo "🌐 URLs:"
echo "   Load Balancer: https://balancer.svdevops.tech"
echo "   Stats: http://$HAPROXY_IP:8080/stats"
echo "   Web1: https://web1.svdevops.tech"
echo "   Web2: https://web2.svdevops.tech"
echo ""
echo "💡 All configurations have been restored from backups/current-state/"
