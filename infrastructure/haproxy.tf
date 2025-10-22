# HAProxy Load Balancer using pre-built image

resource "google_compute_instance" "haproxy" {
  name         = "haproxy-${var.environment}"
  machine_type = var.machine_type
  zone         = var.zone
  
  # Custom memory configuration
  advanced_machine_features {
    enable_nested_virtualization = false
  }

  boot_disk {
    initialize_params {
      image = "haproxy-loadbalancer-image"
      size  = 20
    }
  }

  network_interface {
    network = "default"
    network_ip = google_compute_address.haproxy_internal_ip.address
    access_config {
      nat_ip = google_compute_address.haproxy_static_ip.address
    }
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${var.ssh_public_key}"
  }

  tags = ["load-balancer", "ssh-server"]

  # Startup script - configure HAProxy with separate ports
  metadata_startup_script = <<-EOF
    #!/bin/bash
    # Configure HAProxy with separate ports to avoid conflicts
    
    # Create HAProxy config with separate ports
    cat > /etc/haproxy/haproxy.cfg << 'HAPROXY_EOF'
global
    daemon
    maxconn 4096
    log stdout local0
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin
    stats timeout 30s
    user haproxy
    group haproxy

defaults
    mode http
    log global
    option httplog
    option dontlognull
    option log-health-checks
    option forwardfor
    option httpchk
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

# Frontend for load balancer (balancer.svdevops.tech) - Port 8080
frontend load_balancer
    bind 0.0.0.0:8080
    default_backend web_servers

# Backend for load balancer (balancer.svdevops.tech)
backend web_servers
    balance roundrobin
    option httpchk GET /index.html HTTP/1.0
    http-check expect status 200
    server web1 10.132.15.221:80 check inter 2000ms rise 2 fall 3
    server web2 10.132.15.222:80 check inter 2000ms rise 2 fall 3

# Frontend for web1 (web1.svdevops.tech) - Port 8081
frontend web1_frontend
    bind 0.0.0.0:8081
    default_backend web1_backend

# Backend for web1 (web1.svdevops.tech)
backend web1_backend
    server web1 10.132.15.221:80

# Frontend for web2 (web2.svdevops.tech) - Port 8082
frontend web2_frontend
    bind 0.0.0.0:8082
    default_backend web2_backend

# Backend for web2 (web2.svdevops.tech)
backend web2_backend
    server web2 10.132.15.222:80

# Frontend for stats (stats.svdevops.tech) - Port 8083
frontend stats_frontend
    bind 0.0.0.0:8083
    default_backend stats_backend

# Backend for stats (stats.svdevops.tech) - redirect to stats page
backend stats_backend
    http-request redirect location http://%[req.hdr(host)]:8084/stats code 302

# Stats page - Port 8084
listen stats
    bind 0.0.0.0:8084
    stats enable
    stats uri /stats
    stats refresh 30s
    stats show-node
HAPROXY_EOF

    # Start HAProxy
    systemctl start haproxy
    systemctl enable haproxy
  EOF
}