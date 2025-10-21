#!/bin/bash

# 🔧 Configure HAProxy Script
# This script configures HAProxy with HTTPS support

set -e

echo "🔧 Configuring HAProxy..."

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

# Start HAProxy
sudo systemctl start haproxy

# Check if HAProxy started successfully
if sudo systemctl is-active --quiet haproxy; then
    echo "✅ HAProxy configured and started successfully!"
else
    echo "❌ HAProxy failed to start!"
    sudo systemctl status haproxy --no-pager
    exit 1
fi
