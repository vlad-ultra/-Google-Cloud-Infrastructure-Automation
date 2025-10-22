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

# Allow HAProxy load balancer (Port 8080)
resource "google_compute_firewall" "allow_haproxy_lb" {
  name    = "allow-haproxy-lb-${var.environment}"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["load-balancer"]
}

# Allow HAProxy web1 (Port 8081)
resource "google_compute_firewall" "allow_haproxy_web1" {
  name    = "allow-haproxy-web1-${var.environment}"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["8081"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["load-balancer"]
}

# Allow HAProxy web2 (Port 8082)
resource "google_compute_firewall" "allow_haproxy_web2" {
  name    = "allow-haproxy-web2-${var.environment}"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["8082"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["load-balancer"]
}

# Allow HAProxy stats (Port 8083)
resource "google_compute_firewall" "allow_haproxy_stats" {
  name    = "allow-haproxy-stats-${var.environment}"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["8083"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["load-balancer"]
}

# Allow HAProxy stats page (Port 8084)
resource "google_compute_firewall" "allow_haproxy_stats_page" {
  name    = "allow-haproxy-stats-page-${var.environment}"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["8084"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["load-balancer"]
}
