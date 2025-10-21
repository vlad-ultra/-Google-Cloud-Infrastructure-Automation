# Static Internal IP Addresses
# These IPs are reserved and will not change

# Internal IP for Web Server 1
resource "google_compute_address" "web1_internal_ip" {
  name         = "web1-internal-ip-${var.environment}"
  address_type = "INTERNAL"
  subnetwork   = "default"
  region       = var.region
}

# Internal IP for Web Server 2  
resource "google_compute_address" "web2_internal_ip" {
  name         = "web2-internal-ip-${var.environment}"
  address_type = "INTERNAL"
  subnetwork   = "default"
  region       = var.region
}

# Internal IP for HAProxy
resource "google_compute_address" "haproxy_internal_ip" {
  name         = "haproxy-internal-ip-${var.environment}"
  address_type = "INTERNAL"
  subnetwork   = "default"
  region       = var.region
}
