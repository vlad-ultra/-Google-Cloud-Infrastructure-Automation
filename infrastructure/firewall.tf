# Firewall Rules Configuration

# Allow SSH access
resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh-${var.environment}"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server", "load-balancer", "ssh-server"]
}

# Allow HTTP traffic
resource "google_compute_firewall" "allow_http" {
  name    = "allow-http-${var.environment}"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server", "load-balancer"]
}

# Allow HTTPS traffic
resource "google_compute_firewall" "allow_https" {
  name    = "allow-https-${var.environment}"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server", "load-balancer"]
}

# Allow HAProxy stats
resource "google_compute_firewall" "allow_haproxy_stats" {
  name    = "allow-haproxy-stats-${var.environment}"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["load-balancer"]
}
