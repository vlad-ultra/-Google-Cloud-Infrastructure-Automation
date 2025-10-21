# Static IP Addresses Configuration
# These IPs are persistent and should not be destroyed

# Static IP for HAProxy Load Balancer
resource "google_compute_address" "haproxy_static_ip" {
  name   = "haproxy-static-ip-${var.environment}"
  region = var.region
  
  # Prevent accidental destruction
  lifecycle {
    prevent_destroy = true
  }
}

# Static IP for Web Server 1
resource "google_compute_address" "web1_static_ip" {
  name   = "web1-static-ip-${var.environment}"
  region = var.region
  
  # Prevent accidental destruction
  lifecycle {
    prevent_destroy = true
  }
}

# Static IP for Web Server 2
resource "google_compute_address" "web2_static_ip" {
  name   = "web2-static-ip-${var.environment}"
  region = var.region
  
  # Prevent accidental destruction
  lifecycle {
    prevent_destroy = true
  }
}
