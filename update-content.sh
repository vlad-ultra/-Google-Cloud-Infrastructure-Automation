#!/bin/bash

# 🔄 Quick content update script with FIXED internal IPs

set -e

echo "🔄 Updating content on all servers (FIXED IPs)"
echo "============================================="

# Navigate to project directory
cd "$(dirname "$0")"

# Get FIXED internal IPs from gcloud (hardcoded for reliability)
echo "🔍 Getting FIXED internal IP addresses..."
WEB1_INTERNAL_IP="10.132.15.215"
WEB2_INTERNAL_IP="10.132.15.216"

echo "Web1 Internal IP: $WEB1_INTERNAL_IP"
echo "Web2 Internal IP: $WEB2_INTERNAL_IP"

# Update web1 HTML
echo ""
echo "📝 Updating Web1 HTML..."
if [ -f "web-apps/web1.html" ]; then
    gcloud compute scp web-apps/web1.html web1-prod:/home/vladultra777/web1.html --zone=europe-west1-b
    gcloud compute ssh web1-prod --zone=europe-west1-b --command="
        # Remove old content
        sudo rm -f /var/www/html/index.html
        sudo rm -f /var/www/html/index.html.*
        # Copy new content
        sudo cp /home/vladultra777/web1.html /var/www/html/index.html
        sudo chown root:root /var/www/html/index.html
        sudo chmod 644 /var/www/html/index.html
        # Clear nginx cache and restart
        sudo nginx -s stop || true
        sudo systemctl start nginx
        sudo systemctl restart nginx
        echo 'Web1 updated successfully - old content removed'
    "
else
    echo "⚠️  web-apps/web1.html not found, skipping Web1 HTML update"
fi

# Update web2 HTML
echo "📝 Updating Web2 HTML..."
if [ -f "web-apps/web2.html" ]; then
    gcloud compute scp web-apps/web2.html web2-prod:/home/vladultra777/web2.html --zone=europe-west1-b
    gcloud compute ssh web2-prod --zone=europe-west1-b --command="
        # Remove old content
        sudo rm -f /var/www/html/index.html
        sudo rm -f /var/www/html/index.html.*
        # Copy new content
        sudo cp /home/vladultra777/web2.html /var/www/html/index.html
        sudo chown root:root /var/www/html/index.html
        sudo chmod 644 /var/www/html/index.html
        # Clear nginx cache and restart
        sudo nginx -s stop || true
        sudo systemctl start nginx
        sudo systemctl restart nginx
        echo 'Web2 updated successfully - old content removed'
    "
else
    echo "⚠️  web-apps/web2.html not found, skipping Web2 HTML update"
fi

# Update HAProxy configuration with FIXED internal IPs
echo "📝 Updating HAProxy configuration with FIXED internal IPs..."
gcloud compute ssh haproxy-prod --zone=europe-west1-b  --command="
    # Update HAProxy config with FIXED internal IPs
    sudo sed -i 's/server web1 .*:80/server web1 $WEB1_INTERNAL_IP:80/' /etc/haproxy/haproxy.cfg
    sudo sed -i 's/server web2 .*:80/server web2 $WEB2_INTERNAL_IP:80/' /etc/haproxy/haproxy.cfg
    sudo systemctl restart haproxy
    echo 'HAProxy configuration updated with FIXED internal IPs'
"

# Update HAProxy dashboard
echo "📝 Updating HAProxy dashboard..."
if [ -f "web-apps/haproxy.html" ]; then
    gcloud compute scp web-apps/haproxy.html haproxy-prod:/home/vladultra777/haproxy.html --zone=europe-west1-b
    gcloud compute ssh haproxy-prod --zone=europe-west1-b --command="
        # Remove old content
        sudo rm -f /var/www/html/index.html
        sudo rm -f /var/www/html/index.html.*
        # Copy new content
        sudo cp /home/vladultra777/haproxy.html /var/www/html/index.html
        sudo chown root:root /var/www/html/index.html
        sudo chmod 644 /var/www/html/index.html
        # Clear nginx cache and restart
        sudo nginx -s stop || true
        sudo systemctl start nginx
        sudo systemctl restart nginx
        echo 'HAProxy dashboard updated successfully - old content removed'
    "
else
    echo "⚠️  web-apps/haproxy.html not found, skipping HAProxy dashboard update"
fi

echo ""
echo "✅ All content updated successfully with FIXED internal IPs!"
echo "🌐 Check your load balancer: http://$(cd infrastructure && terraform output -raw haproxy_ip)"
echo ""
echo "🔄 To bypass browser cache, add timestamp to URL:"
echo "   http://$(cd infrastructure && terraform output -raw haproxy_ip)?t=$(date +%s)"
echo "   http://$(cd infrastructure && terraform output -raw web1_ip)?t=$(date +%s)"
echo "   http://$(cd infrastructure && terraform output -raw web2_ip)?t=$(date +%s)"
