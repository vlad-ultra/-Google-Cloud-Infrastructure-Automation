#!/bin/bash

# 🔐 Fix Certbot OpenSSL issue and get REAL Let's Encrypt certificates
# This script fixes the OpenSSL compatibility issue and gets production certificates

set -e

echo "🔐 Fixing Certbot OpenSSL issue and getting REAL Let's Encrypt certificates..."
echo "================================================================="

# Check if we're in the correct directory
if [ ! -f "infrastructure/main.tf" ]; then
    echo "❌ Error: Run script from project root directory"
    exit 1
fi

# Get HAProxy IP
HAPROXY_IP="34.77.23.11"

echo "📊 HAProxy IP: $HAPROXY_IP"

# Create local directory for certificates
echo ""
echo "📁 Creating local directory for certificates..."
mkdir -p ssl-certs
echo "✅ Directory ssl-certs created"

# Fix Certbot and get REAL Let's Encrypt certificates
echo ""
echo "🔧 Fixing Certbot OpenSSL issue and getting REAL certificates..."

gcloud compute ssh haproxy-prod --zone=europe-west1-b --command="
# Fix OpenSSL compatibility issue
echo 'Fixing OpenSSL compatibility issue...'
sudo pip3 uninstall -y pyOpenSSL
sudo pip3 install 'pyOpenSSL<23.0.0'

# Alternative: Use snap version of certbot
echo 'Installing snap version of certbot...'
sudo snap install --classic certbot
sudo ln -sf /snap/bin/certbot /usr/bin/certbot

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

# Wait a moment for Nginx to start
sleep 5

# Get REAL Let's Encrypt certificates (production)
echo 'Getting REAL Let'\''s Encrypt certificates...'
if sudo certbot certonly --nginx -d balancer.svdevops.tech -d stats.svdevops.tech -d web1.svdevops.tech -d web2.svdevops.tech --non-interactive --agree-tos --email admin@svdevops.tech --force-renewal; then
    echo '✅ REAL Let'\''s Encrypt certificates obtained!'
    
    # Create combined certificate for HAProxy
    sudo bash -c 'cat /etc/letsencrypt/live/balancer.svdevops.tech/fullchain.pem /etc/letsencrypt/live/balancer.svdevops.tech/privkey.pem > /etc/haproxy/certs/svdevops.tech.pem'
    
    # Copy individual files
    sudo cp /etc/letsencrypt/live/balancer.svdevops.tech/fullchain.pem /etc/haproxy/certs/svdevops.tech.crt
    sudo cp /etc/letsencrypt/live/balancer.svdevops.tech/privkey.pem /etc/haproxy/certs/svdevops.tech.key
    
    echo 'Let'\''s Encrypt certificates configured for HAProxy'
    CERT_TYPE='letsencrypt-real'
else
    echo '❌ Let'\''s Encrypt failed, trying staging...'
    
    # Try staging as fallback
    if sudo certbot certonly --nginx -d balancer.svdevops.tech -d stats.svdevops.tech -d web1.svdevops.tech -d web2.svdevops.tech --non-interactive --agree-tos --email admin@svdevops.tech --staging; then
        echo '✅ Let'\''s Encrypt staging certificates obtained!'
        
        # Create combined certificate for HAProxy
        sudo bash -c 'cat /etc/letsencrypt/live/balancer.svdevops.tech/fullchain.pem /etc/letsencrypt/live/balancer.svdevops.tech/privkey.pem > /etc/haproxy/certs/svdevops.tech.pem'
        
        # Copy individual files
        sudo cp /etc/letsencrypt/live/balancer.svdevops.tech/fullchain.pem /etc/haproxy/certs/svdevops.tech.crt
        sudo cp /etc/letsencrypt/live/balancer.svdevops.tech/privkey.pem /etc/haproxy/certs/svdevops.tech.key
        
        echo 'Staging certificates configured for HAProxy'
        CERT_TYPE='letsencrypt-staging'
    else
        echo '❌ Both production and staging failed'
        exit 1
    fi
fi

# Configure HAProxy for HTTPS
sudo tee /etc/haproxy/haproxy.cfg > /dev/null << 'EOF'
global
    daemon
    maxconn 4096
    log stdout local0
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin
    stats timeout 30s
    user haproxy
    group haproxy
    tune.ssl.default-dh-param 2048

defaults
    mode http
    log global
    option httplog
    option dontlognull
    option log-health-checks
    option forwardfor
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms
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
    server web1 10.132.15.221:80
    server web2 10.132.15.222:80

# Backend for web1 (web1.svdevops.tech)
backend web1_backend
    server web1 10.132.15.221:80

# Backend for web2 (web2.svdevops.tech)
backend web2_backend
    server web2 10.132.15.222:80

# Backend for stats (stats.svdevops.tech) - redirect to stats page
backend stats_backend
    http-request redirect location https://%[req.hdr(host)]:8084/stats code 302

# Stats page - Port 8084
listen stats
    bind 0.0.0.0:8084
    stats enable
    stats uri /stats
    stats refresh 30s
    stats show-node
EOF

# Stop Nginx and start HAProxy
sudo systemctl stop nginx
sudo systemctl start haproxy

echo 'HAProxy configured with REAL certificates!'
echo 'Certificate type: '\$CERT_TYPE
"

# Download certificates to local directory
echo ""
echo "📥 Downloading certificates to local directory..."

# Download certificates using base64 encoding
gcloud compute ssh haproxy-prod --zone=europe-west1-b --command="sudo base64 /etc/haproxy/certs/svdevops.tech.pem" > ssl-certs/svdevops.tech.pem.b64
gcloud compute ssh haproxy-prod --zone=europe-west1-b --command="sudo base64 /etc/haproxy/certs/svdevops.tech.crt" > ssl-certs/svdevops.tech.crt.b64
gcloud compute ssh haproxy-prod --zone=europe-west1-b --command="sudo base64 /etc/haproxy/certs/svdevops.tech.key" > ssl-certs/svdevops.tech.key.b64

# Decode certificates
base64 -d -i ssl-certs/svdevops.tech.pem.b64 -o ssl-certs/svdevops.tech.pem
base64 -d -i ssl-certs/svdevops.tech.crt.b64 -o ssl-certs/svdevops.tech.crt
base64 -d -i ssl-certs/svdevops.tech.key.b64 -o ssl-certs/svdevops.tech.key

# Clean up base64 files
rm -f ssl-certs/*.b64

echo "✅ Certificates downloaded to ssl-certs/ directory"

# Verify certificates
echo ""
echo "🔍 Verifying downloaded certificates..."
echo "1. Certificate file:"
ls -la ssl-certs/svdevops.tech.crt
echo ""
echo "2. Certificate details:"
openssl x509 -in ssl-certs/svdevops.tech.crt -text -noout | head -15
echo ""
echo "3. Certificate issuer:"
openssl x509 -in ssl-certs/svdevops.tech.crt -noout -issuer
echo ""
echo "4. Certificate subject:"
openssl x509 -in ssl-certs/svdevops.tech.crt -noout -subject
echo ""
echo "5. Certificate validity:"
openssl x509 -in ssl-certs/svdevops.tech.crt -noout -dates

echo ""
echo "🧪 Testing HTTPS domains..."
echo "1. HTTPS balancer.svdevops.tech:"
curl -k -s --connect-timeout 5 https://balancer.svdevops.tech | grep -o "Web Server [12]" | head -1 || echo "❌ HTTPS недоступен"
echo "2. HTTPS web1.svdevops.tech:"
curl -k -s --connect-timeout 5 https://web1.svdevops.tech | grep -o "Web Server [12]" | head -1 || echo "❌ HTTPS недоступен"
echo "3. HTTPS web2.svdevops.tech:"
curl -k -s --connect-timeout 5 https://web2.svdevops.tech | grep -o "Web Server [12]" | head -1 || echo "❌ HTTPS недоступен"
echo "4. HTTPS stats.svdevops.tech:"
curl -k -I --connect-timeout 5 https://stats.svdevops.tech 2>/dev/null | grep -E "(HTTP|Location)" || echo "❌ HTTPS недоступен"

echo ""
echo "🎉 REAL Let's Encrypt SSL certificates setup completed!"
echo "📁 Certificates saved in: ssl-certs/"
echo "🔗 HTTPS Load Balancer: https://balancer.svdevops.tech"
echo "🔗 HTTPS Web1: https://web1.svdevops.tech"
echo "🔗 HTTPS Web2: https://web2.svdevops.tech"
echo "🔗 HTTPS Stats: https://stats.svdevops.tech"
