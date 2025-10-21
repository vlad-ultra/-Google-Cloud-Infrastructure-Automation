# Outputs for Load Balancer Infrastructure

# HAProxy outputs
output "haproxy_ip" {
  description = "HAProxy Load Balancer Static IP"
  value       = google_compute_address.haproxy_static_ip.address
}

output "haproxy_ssh_command" {
  description = "SSH command to connect to HAProxy"
  value       = "gcloud compute ssh haproxy-${var.environment} --zone=${var.zone}"
}

output "haproxy_stats_url" {
  description = "HAProxy Statistics URL"
  value       = "http://${google_compute_address.haproxy_static_ip.address}:8080/stats"
}

# Web servers outputs
output "web1_ip" {
  description = "Web Server 1 Static IP"
  value       = google_compute_address.web1_static_ip.address
}

output "web1_internal_ip" {
  description = "Web Server 1 Internal IP"
  value       = google_compute_address.web1_internal_ip.address
}

output "web2_ip" {
  description = "Web Server 2 Static IP"
  value       = google_compute_address.web2_static_ip.address
}

output "web2_internal_ip" {
  description = "Web Server 2 Internal IP"
  value       = google_compute_address.web2_internal_ip.address
}

output "web1_ssh_command" {
  description = "SSH command to connect to Web Server 1"
  value       = "gcloud compute ssh web1-${var.environment} --zone=${var.zone}"
}

output "web2_ssh_command" {
  description = "SSH command to connect to Web Server 2"
  value       = "gcloud compute ssh web2-${var.environment} --zone=${var.zone}"
}

# Load balancer URLs
output "load_balancer_url" {
  description = "Load Balancer URL (main entry point)"
  value       = "http://${google_compute_address.haproxy_static_ip.address}"
}

output "web_servers_direct_urls" {
  description = "Direct URLs to web servers"
  value = {
    "web-server-1" = "http://${google_compute_address.web1_static_ip.address}"
    "web-server-2" = "http://${google_compute_address.web2_static_ip.address}"
  }
}
