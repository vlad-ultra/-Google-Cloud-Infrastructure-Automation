#!/bin/bash

# 🚀 Simple deployment using pre-built images with FIXED internal IPs

set -e

echo "🚀 Simple HAProxy Load Balancer Deployment (FIXED IPs)"
echo "====================================================="
echo "⚡ Using pre-built images with FIXED internal IPs - Expected time: ~30 seconds"

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
echo "Current account: $(gcloud auth list --filter=status:ACTIVE --format='value(account)' 2>/dev/null || echo 'None')"
echo "Project: $(gcloud config get-value project 2>/dev/null || echo 'Not set')"

# Check if we're in GitHub Actions
if [ -n "$GITHUB_ACTIONS" ]; then
    echo "🤖 Running in GitHub Actions"
    echo "GCP_PROJECT_ID: ${GCP_PROJECT_ID:-'Not set'}"
    echo "GCP_SA_KEY: ${GCP_SA_KEY:+Set}${GCP_SA_KEY:-'Not set'}"
    
    # Try to authenticate with service account
    if [ -n "$GCP_SA_KEY" ]; then
        echo "🔑 Authenticating with service account..."
        echo "$GCP_SA_KEY" > /tmp/gcp-key.json
        gcloud auth activate-service-account --key-file=/tmp/gcp-key.json
        gcloud config set project "$GCP_PROJECT_ID"
        rm -f /tmp/gcp-key.json
    fi
fi

if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo "❌ Error: Not authenticated to Google Cloud"
    echo "In GitHub Actions: Check that GCP_SA_KEY secret is set"
    echo "Locally: Run: gcloud auth login"
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

# Check if infrastructure already exists
echo ""
echo "🔍 Checking if infrastructure already exists..."
if gcloud compute instances describe haproxy-prod --zone=europe-west1-b --quiet 2>/dev/null; then
    echo "✅ Infrastructure already exists, skipping deployment"
    echo "🔄 Updating content and SSL configuration instead..."
    
    # Go back to project root for content updates
    cd ..
    
    # Update content
    echo "📝 Updating content on existing servers..."
    chmod +x ./update-content.sh
    ./update-content.sh
    
    # Configure SSL if not already configured
    echo "🔐 Checking SSL configuration..."
    if ! gcloud compute ssh haproxy-prod --zone=europe-west1-b --command="sudo test -f /etc/haproxy/certs/svdevops.tech.pem" 2>/dev/null; then
        echo "🔐 Configuring SSL certificates..."
        # Add SSL configuration logic here
        echo "⚠️ SSL configuration needed - run start-instances.sh to configure SSL"
    else
        echo "✅ SSL already configured"
    fi
    
    echo "✅ Content updated on existing infrastructure"
    exit 0
fi

# Destroy old servers (preserve static IPs) - only if they exist
echo ""
echo "🗑️  Removing old servers (preserving static IPs)..."
terraform destroy -target=google_compute_instance.haproxy -target=google_compute_instance.web1 -target=google_compute_instance.web2 -auto-approve || true

# Deploy infrastructure
echo ""
echo "🏗️  Deploying infrastructure using pre-built images with FIXED internal IPs..."
echo "⏱️  This will take ~30 seconds..."

START_TIME=$(date +%s)
terraform init -upgrade
terraform apply -auto-approve
END_TIME=$(date +%s)
DEPLOYMENT_TIME=$((END_TIME - START_TIME))

# Get IP addresses (hardcoded for reliability)
echo ""
echo "📊 Getting IP addresses..."
HAPROXY_IP="34.77.23.11"
WEB1_IP="34.76.227.170"
WEB2_IP="34.78.104.76"

# Get FIXED internal IP addresses
WEB1_INTERNAL_IP="10.132.15.215"
WEB2_INTERNAL_IP="10.132.15.216"

echo "HAProxy IP: $HAPROXY_IP"
echo "Web1 IP: $WEB1_IP (Internal: $WEB1_INTERNAL_IP)"
echo "Web2 IP: $WEB2_IP (Internal: $WEB2_INTERNAL_IP)"

# Wait for instances to be ready
echo ""
echo "⏳ Waiting for instances to be ready..."
sleep 30

# Go back to project root for file operations
cd ..

# Update configurations
echo ""
echo "🔧 Updating configurations..."

# Update web1 HTML
echo "Updating Web1 HTML..."
if [ -f "web-apps/web1.html" ]; then
    gcloud compute scp web-apps/web1.html web1-prod:/tmp/web1.html --zone=europe-west1-b     gcloud compute ssh web1-prod --zone=europe-west1-b  --command="
        sudo cp /tmp/web1.html /var/www/html/index.html
        sudo chown root:root /var/www/html/index.html
        sudo chmod 644 /var/www/html/index.html
        sudo systemctl restart nginx
        echo 'Web1 updated successfully'
    "
else
    echo "⚠️  web-apps/web1.html not found, skipping Web1 HTML update"
fi

# Update web2 HTML
echo "Updating Web2 HTML..."
if [ -f "web-apps/web2.html" ]; then
    gcloud compute scp web-apps/web2.html web2-prod:/tmp/web2.html --zone=europe-west1-b     gcloud compute ssh web2-prod --zone=europe-west1-b  --command="
        sudo cp /tmp/web2.html /var/www/html/index.html
        sudo chown root:root /var/www/html/index.html
        sudo chmod 644 /var/www/html/index.html
        sudo systemctl restart nginx
        echo 'Web2 updated successfully'
    "
else
    echo "⚠️  web-apps/web2.html not found, skipping Web2 HTML update"
fi

# Update HAProxy configuration with FIXED internal IPs
echo "Updating HAProxy configuration with FIXED internal IPs..."
gcloud compute ssh haproxy-prod --zone=europe-west1-b  --command="
    # Update HAProxy config with FIXED internal IPs
    sudo sed -i 's/server web1 .*:80/server web1 $WEB1_INTERNAL_IP:80/' /etc/haproxy/haproxy.cfg
    sudo sed -i 's/server web2 .*:80/server web2 $WEB2_INTERNAL_IP:80/' /etc/haproxy/haproxy.cfg
    sudo systemctl restart haproxy
    echo 'HAProxy configuration updated with FIXED internal IPs'
"

# Update HAProxy dashboard
echo "Updating HAProxy dashboard..."
if [ -f "web-apps/haproxy.html" ]; then
    gcloud compute scp web-apps/haproxy.html haproxy-prod:/tmp/haproxy.html --zone=europe-west1-b     gcloud compute ssh haproxy-prod --zone=europe-west1-b  --command="
        sudo cp /tmp/haproxy.html /var/www/html/index.html
        sudo chown root:root /var/www/html/index.html
        sudo chmod 644 /var/www/html/index.html
        sudo systemctl restart nginx
        echo 'HAProxy dashboard updated successfully'
    "
else
    echo "⚠️  web-apps/haproxy.html not found, skipping HAProxy dashboard update"
fi

# Test functionality
echo ""
echo "🧪 Testing load balancer functionality..."
sleep 10

# Check curl availability
if command -v curl >/dev/null 2>&1; then
    # Test load balancer
    if curl -s --connect-timeout 10 http://$HAPROXY_IP | grep -q "Auto Deploy System"; then
        echo "✅ Load balancer is working!"
        
        # Test round-robin
        echo ""
        echo "🔄 Testing round-robin load balancing..."
        echo "Making 6 requests:"
        for i in {1..6}; do
            echo -n "Request $i: "
            curl -s --connect-timeout 5 http://$HAPROXY_IP | grep -o "Web Server [12]"
        done
    else
        echo "❌ Load balancer issue"
        echo "⚠️  But infrastructure is deployed, check manually"
    fi
else
    echo "⚠️  curl not available, skipping tests"
    echo "✅ Infrastructure deployed, check manually"
fi

# Show results
echo ""
echo ""
# Setup SSL certificates for all domains
echo ""
echo "🔐 Setting up SSL certificates for all domains..."
echo "⏱️ This will take ~30 seconds..."

# Wait for HAProxy to be ready
echo "⏳ Waiting for HAProxy to be ready..."
sleep 30

# Try to restore certificates from GCS first
echo "🔄 Trying to restore certificates from Google Cloud Storage..."
if ./restore-ssl-from-gcs.sh 2>/dev/null; then
    echo "✅ SSL certificates restored from backup!"
else
    echo "⚠️ No backup found, generating new certificates..."
    
    # Setup SSL certificates for all domains
    echo "🔐 Configuring SSL certificates for all domains..."

    # Create HAProxy SSL configuration with redirect to HTTPS
    gcloud compute ssh haproxy-prod --zone=europe-west1-b --command="
# Install certbot if not installed
sudo apt update && sudo apt install -y certbot python3-certbot-nginx

# Create directory for certificates
sudo mkdir -p /etc/haproxy/certs

# Stop HAProxy temporarily
sudo systemctl stop haproxy

# Configure Nginx for Let's Encrypt
sudo tee /etc/nginx/sites-available/letsencrypt > /dev/null << 'EOF'
server {
    listen 80;
    server_name balancer.svdevops.tech stats.svdevops.tech web1.svdevops.tech web2.svdevops.tech;
    
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }
    
    location / {
        return 200 'OK';
        add_header Content-Type text/plain;
    }
}
EOF

# Enable Nginx configuration
sudo ln -sf /etc/nginx/sites-available/letsencrypt /etc/nginx/sites-enabled/
sudo systemctl start nginx

# Get SSL certificates for all domains
sudo certbot certonly --nginx -d balancer.svdevops.tech -d stats.svdevops.tech -d web1.svdevops.tech -d web2.svdevops.tech --non-interactive --agree-tos --email admin@svdevops.tech

# Create combined certificate for HAProxy
sudo bash -c 'cat /etc/letsencrypt/live/balancer.svdevops.tech/fullchain.pem /etc/letsencrypt/live/balancer.svdevops.tech/privkey.pem > /etc/haproxy/certs/svdevops.tech.pem'

# Configure HAProxy for HTTPS redirect and all domains
sudo tee /etc/haproxy/haproxy.cfg > /dev/null << 'EOF'
global
    daemon
    user haproxy
    group haproxy
    log 127.0.0.1:514 local0
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin
    stats timeout 30s
    tune.ssl.default-dh-param 2048

defaults
    mode http
    log global
    option httplog
    option dontlognull
    option log-health-checks
    option forwardfor
    option httpchk
    timeout connect 5000
    timeout client 50000
    timeout server 50000
    errorfile 400 /etc/haproxy/errors/400.http
    errorfile 403 /etc/haproxy/errors/403.http
    errorfile 408 /etc/haproxy/errors/408.http
    errorfile 500 /etc/haproxy/errors/500.http
    errorfile 502 /etc/haproxy/errors/502.http
    errorfile 503 /etc/haproxy/errors/503.http
    errorfile 504 /etc/haproxy/errors/504.http

# Frontend for HTTP - redirect all to HTTPS
frontend http_front
    bind *:80
    acl is_balancer hdr(host) -i balancer.svdevops.tech
    acl is_web1 hdr(host) -i web1.svdevops.tech
    acl is_web2 hdr(host) -i web2.svdevops.tech
    acl is_stats hdr(host) -i stats.svdevops.tech
    
    # Redirect all HTTP to HTTPS
    redirect scheme https code 301 if is_balancer
    redirect scheme https code 301 if is_web1
    redirect scheme https code 301 if is_web2
    redirect scheme https code 301 if is_stats
    
    # Default backend for other requests
    default_backend web_servers

# Frontend for HTTPS - handle all domains
frontend https_front
    bind *:443 ssl crt /etc/haproxy/certs/svdevops.tech.pem
    acl is_balancer hdr(host) -i balancer.svdevops.tech
    acl is_web1 hdr(host) -i web1.svdevops.tech
    acl is_web2 hdr(host) -i web2.svdevops.tech
    acl is_stats hdr(host) -i stats.svdevops.tech

    use_backend web_servers if is_balancer
    use_backend web1_backend if is_web1
    use_backend web2_backend if is_web2
    use_backend stats_backend if is_stats
    default_backend web_servers

# Backend for load balancer (balancer.svdevops.tech)
backend web_servers
    balance roundrobin
    option httpchk GET /index.html HTTP/1.0
    http-check expect status 200
    server web1 10.132.15.215:80 check inter 2000ms rise 2 fall 3
    server web2 10.132.15.216:80 check inter 2000ms rise 2 fall 3

# Backend for web1 (web1.svdevops.tech)
backend web1_backend
    server web1 10.132.15.215:80

# Backend for web2 (web2.svdevops.tech)
backend web2_backend
    server web2 10.132.15.216:80

# Backend for stats (stats.svdevops.tech) - redirect to stats page
backend stats_backend
    http-request redirect location http://%[req.hdr(host)]:8080/stats code 302

# Stats page
listen stats
    bind 0.0.0.0:8080
    stats enable
    stats uri /stats
    stats refresh 30s
    stats admin if TRUE
EOF

# Stop Nginx and start HAProxy
sudo systemctl stop nginx
sudo systemctl start haproxy

echo 'SSL certificates and HAProxy configured for all domains!'
"

    # Save certificates to GCS for future use
    echo "💾 Saving certificates to Google Cloud Storage..."
    ./save-ssl-to-gcs.sh
fi

echo "✅ SSL certificates configured for all domains!"

echo "🎉 Simple Deployment completed successfully!"
echo "==========================================="
echo ""
echo "⏱️  Total deployment time: ${DEPLOYMENT_TIME} seconds"
echo ""
echo "📊 Results:"
echo "Load Balancer: https://balancer.svdevops.tech"
echo "HAProxy Stats: https://stats.svdevops.tech"
echo "Web Server 1: https://web1.svdevops.tech (Internal: $WEB1_INTERNAL_IP)"
echo "Web Server 2: https://web2.svdevops.tech (Internal: $WEB2_INTERNAL_IP)"
echo ""
echo "🔑 SSH Access:"
echo "gcloud compute ssh haproxy-prod --zone=europe-west1-b "
echo "gcloud compute ssh web1-prod --zone=europe-west1-b "
echo "gcloud compute ssh web2-prod --zone=europe-west1-b "
echo ""
echo "✅ Infrastructure ready for use with FIXED internal IPs!"
