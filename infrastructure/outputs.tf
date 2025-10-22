# External IPs
output "haproxy_external_ip" {
  description = "HAProxy external IP address"
  value       = google_compute_address.haproxy_static_ip.address
}

output "web1_external_ip" {
  description = "Web1 external IP address"
  value       = google_compute_address.web1_static_ip.address
}

output "web2_external_ip" {
  description = "Web2 external IP address"
  value       = google_compute_address.web2_static_ip.address
}

# Internal IPs
output "haproxy_internal_ip" {
  description = "HAProxy internal IP address"
  value       = google_compute_address.haproxy_internal_ip.address
}

output "web1_internal_ip" {
  description = "Web1 internal IP address"
  value       = google_compute_address.web1_internal_ip.address
}

output "web2_internal_ip" {
  description = "Web2 internal IP address"
  value       = google_compute_address.web2_internal_ip.address
}

# Main URLs
output "load_balancer_url" {
  description = "Load Balancer URL"
  value       = "https://balancer.svdevops.tech"
}

output "stats_url" {
  description = "HAProxy Stats URL"
  value       = "https://balancer.svdevops.tech/stats"
}

output "web1_url" {
  description = "Web1 URL"
  value       = "https://web1.svdevops.tech"
}

output "web2_url" {
  description = "Web2 URL"
  value       = "https://web2.svdevops.tech"
}

# Direct access URLs (for testing)
output "haproxy_direct_http" {
  description = "HAProxy direct HTTP access"
  value       = "http://${google_compute_address.haproxy_static_ip.address}:8080/stats"
}

output "haproxy_direct_https" {
  description = "HAProxy direct HTTPS access"
  value       = "https://${google_compute_address.haproxy_static_ip.address}:8443/stats"
}

# Project information
output "project_info" {
  description = "Project deployment information"
  value = {
    environment = var.environment
    region      = var.region
    machine_type = var.machine_type
    deployment_time = timestamp()
  }
}
