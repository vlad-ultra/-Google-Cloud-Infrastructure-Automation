#!/bin/bash

# 🚀 Start Instances Script
# This script starts all instances back up

set -e

echo "🚀 Starting Instances"
echo "===================="

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

# Get instance names
HAPROXY_INSTANCE="haproxy-prod"
WEB1_INSTANCE="web1-prod"
WEB2_INSTANCE="web2-prod"
ZONE="europe-west1-b"

echo ""
echo "Starting instances: ${HAPROXY_INSTANCE}, ${WEB1_INSTANCE}, ${WEB2_INSTANCE} in zone ${ZONE}..."
echo "⏱️ This will take ~30 seconds..."

START_TIME=$(date +%s)

# Start HAProxy instance
echo "🚀 Starting HAProxy..."
gcloud compute instances start "${HAPROXY_INSTANCE}" --zone="${ZONE}" --project="${PROJECT_ID}" --quiet || true &
HAPROXY_PID=$!

# Start Web1 instance
echo "🚀 Starting Web1..."
gcloud compute instances start "${WEB1_INSTANCE}" --zone="${ZONE}" --project="${PROJECT_ID}" --quiet || true &
WEB1_PID=$!

# Start Web2 instance
echo "🚀 Starting Web2..."
gcloud compute instances start "${WEB2_INSTANCE}" --zone="${ZONE}" --project="${PROJECT_ID}" --quiet || true &
WEB2_PID=$!

# Wait for all starts to complete
wait $HAPROXY_PID $WEB1_PID $WEB2_PID

# Wait for instances to be ready
echo "⏳ Waiting for instances to be ready..."
sleep 30

# Configure SSL certificates and HAProxy for new architecture
echo ""
echo "⚡ Configuring SSL certificates and HAProxy for new architecture..."

# Configure SSL on web1
echo "🔐 Configuring SSL on web1..."
gcloud compute ssh web1-prod --zone=europe-west1-b --command="
# Install certbot if not installed
sudo apt update && sudo apt install -y certbot python3-certbot-nginx

# Stop nginx
sudo systemctl stop nginx

# Get SSL certificate for web1.svdevops.tech
sudo certbot certonly --standalone -d web1.svdevops.tech --non-interactive --agree-tos --email admin@svdevops.tech

# Configure nginx for SSL
sudo tee /etc/nginx/sites-available/web1-ssl > /dev/null << 'EOF'
server {
    listen 80;
    server_name web1.svdevops.tech;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl;
    server_name web1.svdevops.tech;
    
    ssl_certificate /etc/letsencrypt/live/web1.svdevops.tech/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/web1.svdevops.tech/privkey.pem;
    
    root /var/www/html;
    index index.html index.htm;
    
    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF

# Enable SSL configuration
sudo ln -sf /etc/nginx/sites-available/web1-ssl /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Start nginx
sudo systemctl start nginx

echo 'SSL configured on web1!'
"

# Configure SSL on web2
echo "🔐 Configuring SSL on web2..."
gcloud compute ssh web2-prod --zone=europe-west1-b --command="
# Install certbot if not installed
sudo apt update && sudo apt install -y certbot python3-certbot-nginx

# Stop nginx
sudo systemctl stop nginx

# Get SSL certificate for web2.svdevops.tech
sudo certbot certonly --standalone -d web2.svdevops.tech --non-interactive --agree-tos --email admin@svdevops.tech

# Configure nginx for SSL
sudo tee /etc/nginx/sites-available/web2-ssl > /dev/null << 'EOF'
server {
    listen 80;
    server_name web2.svdevops.tech;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl;
    server_name web2.svdevops.tech;
    
    ssl_certificate /etc/letsencrypt/live/web2.svdevops.tech/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/web2.svdevops.tech/privkey.pem;
    
    root /var/www/html;
    index index.html index.htm;
    
    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF

# Enable SSL configuration
sudo ln -sf /etc/nginx/sites-available/web2-ssl /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Start nginx
sudo systemctl start nginx

echo 'SSL configured on web2!'
"

# Configure HAProxy for new architecture
echo "🔧 Configuring HAProxy for new architecture..."
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
    server_name balancer.svdevops.tech stats.svdevops.tech;
    
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

# Get SSL certificates for balancer and stats
sudo certbot certonly --nginx -d balancer.svdevops.tech -d stats.svdevops.tech --non-interactive --agree-tos --email admin@svdevops.tech

# Create combined certificate for HAProxy
sudo bash -c 'cat /etc/letsencrypt/live/balancer.svdevops.tech/fullchain.pem /etc/letsencrypt/live/balancer.svdevops.tech/privkey.pem > /etc/haproxy/certs/svdevops.tech.pem'

# Configure HAProxy for new architecture
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

# Backend for load balancer (balancer.svdevops.tech) - HTTPS roundrobin
backend web_servers
    balance roundrobin
    option httpchk GET /index.html HTTP/1.0
    http-check expect status 200
    server web1 10.132.15.215:443 ssl verify none check inter 2000ms rise 2 fall 3
    server web2 10.132.15.216:443 ssl verify none check inter 2000ms rise 2 fall 3

# Backend for web1 (web1.svdevops.tech) - HTTPS
backend web1_backend
    server web1 10.132.15.215:443 ssl verify none

# Backend for web2 (web2.svdevops.tech) - HTTPS
backend web2_backend
    server web2 10.132.15.216:443 ssl verify none

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

echo 'HAProxy configured for new architecture!'
"

END_TIME=$(date +%s)
START_TIME_TOTAL=$((END_TIME - START_TIME))

echo ""
echo "🎉 All instances started and configured successfully!"
echo "====================================================="
echo ""
echo "⏱️ Total start time: ${START_TIME_TOTAL} seconds"
echo ""
echo "🌐 Access URLs:"
echo "Load Balancer (Roundrobin): https://balancer.svdevops.tech"
echo "HAProxy Stats: https://stats.svdevops.tech"
echo "Web Server 1 (Direct): https://web1.svdevops.tech"
echo "Web Server 2 (Direct): https://web2.svdevops.tech"
echo ""
echo "🔧 Architecture:"
echo "- Each web server has its own SSL certificate"
echo "- HAProxy uses HTTPS roundrobin for load balancing"
echo "- All domains work through HTTPS"
echo ""
echo "🛑 To stop instances and save money, run:"
echo "   ./stop-instances.sh"
echo ""
echo "✅ All instances started and ready with new architecture!"
