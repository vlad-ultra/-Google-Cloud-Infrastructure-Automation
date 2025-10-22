#!/bin/bash

# 🔐 Export SSL certificate from Google Cloud and configure HAProxy
# This script waits for GCP managed certificate to be ready and exports it

set -e

echo "🔐 Exporting SSL certificate from Google Cloud..."
echo "================================================================="

# Check if we're in the correct directory
if [ ! -f "infrastructure/main.tf" ]; then
    echo "❌ Error: Run script from project root directory"
    exit 1
fi

# Get HAProxy IP
HAPROXY_IP="34.77.23.11"

echo "📊 HAProxy IP: $HAPROXY_IP"

# Function to check certificate status
check_cert_status() {
    local status=$(gcloud compute ssl-certificates describe svdevops-ssl-cert --global --format="value(managed.status)" 2>/dev/null)
    echo "$status"
}

# Function to wait for certificate to be ready
wait_for_cert() {
    echo "⏳ Waiting for Google Cloud certificate to be ready..."
    local max_attempts=60  # 10 minutes max
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        local status=$(check_cert_status)
        echo "📊 Certificate status: $status (attempt $((attempt + 1))/$max_attempts)"
        
        if [ "$status" = "ACTIVE" ]; then
            echo "✅ Certificate is ready!"
            return 0
        elif [ "$status" = "PROVISIONING" ]; then
            echo "⏳ Still provisioning, waiting 10 seconds..."
            sleep 10
            attempt=$((attempt + 1))
        else
            echo "❌ Certificate status: $status (unexpected)"
            return 1
        fi
    done
    
    echo "❌ Timeout waiting for certificate to be ready"
    return 1
}

# Wait for certificate to be ready
if wait_for_cert; then
    echo "✅ Google Cloud certificate is ready!"
else
    echo "⚠️ Google Cloud certificate not ready, using fallback..."
    # Use the existing valid self-signed certificate
    gcloud compute ssh haproxy-prod --zone=europe-west1-b --command="
        echo 'Using existing valid self-signed certificate'
        ls -la /etc/haproxy/certs/
    "
    exit 0
fi

# Export certificate from Google Cloud
echo ""
echo "📤 Exporting certificate from Google Cloud..."

# Get certificate details
CERT_NAME="svdevops-ssl-cert"
CERT_DOMAINS=("balancer.svdevops.tech" "stats.svdevops.tech" "web1.svdevops.tech" "web2.svdevops.tech")

# Note: Google Cloud managed certificates cannot be directly exported
# They are only available for use with Google Cloud Load Balancer
echo "⚠️ Google Cloud managed certificates cannot be directly exported"
echo "💡 They are only available for use with Google Cloud Load Balancer"
echo "🔧 Using alternative approach: Create certificate from Google Cloud domains"

# Create a new certificate using the same domains
echo ""
echo "🔧 Creating new certificate for the same domains..."

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

# Try to get Let's Encrypt certificates
echo 'Trying to get Let'\''s Encrypt certificates...'
if sudo certbot certonly --nginx -d balancer.svdevops.tech -d stats.svdevops.tech -d web1.svdevops.tech -d web2.svdevops.tech --non-interactive --agree-tos --email admin@svdevops.tech 2>/dev/null; then
    echo 'Let'\''s Encrypt certificates obtained!'
    # Create combined certificate for HAProxy
    sudo bash -c 'cat /etc/letsencrypt/live/balancer.svdevops.tech/fullchain.pem /etc/letsencrypt/live/balancer.svdevops.tech/privkey.pem > /etc/haproxy/certs/svdevops.tech.pem'
    CERT_TYPE='letsencrypt'
else
    echo 'Let'\''s Encrypt failed, creating valid self-signed certificate...'
    # Create OpenSSL config file for proper SAN
    sudo tee /etc/ssl/openssl.cnf.local > /dev/null << 'OPENSSL_EOF'
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
req_extensions = v3_req

[dn]
C=US
ST=State
L=City
O=Organization
CN=svdevops.tech

[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = balancer.svdevops.tech
DNS.2 = stats.svdevops.tech
DNS.3 = web1.svdevops.tech
DNS.4 = web2.svdevops.tech
DNS.5 = svdevops.tech
OPENSSL_EOF

    # Create valid self-signed certificate with proper SAN
    sudo openssl req -new -x509 -newkey rsa:2048 -sha256 -nodes \
        -keyout /etc/haproxy/certs/svdevops.tech.key \
        -days 365 \
        -out /etc/haproxy/certs/svdevops.tech.crt \
        -config /etc/ssl/openssl.cnf.local
    
    # Combine certificate and key for HAProxy
    sudo bash -c 'cat /etc/haproxy/certs/svdevops.tech.crt /etc/haproxy/certs/svdevops.tech.key > /etc/haproxy/certs/svdevops.tech.pem'
    CERT_TYPE='self-signed-valid'
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

echo 'HAProxy configured with certificate!'
echo 'Certificate type: '\$CERT_TYPE
"

echo ""
echo "✅ Certificate configuration completed!"
echo "📊 Certificate type: $CERT_TYPE"

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
echo "🎉 SSL certificate setup completed!"
echo "🔗 HTTPS Load Balancer: https://balancer.svdevops.tech"
echo "🔗 HTTPS Web1: https://web1.svdevops.tech"
echo "🔗 HTTPS Web2: https://web2.svdevops.tech"
echo "🔗 HTTPS Stats: https://stats.svdevops.tech"
