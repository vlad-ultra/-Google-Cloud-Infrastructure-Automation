# Web Server 1
resource "google_compute_instance" "web1" {
  name         = "web1-${var.environment}"
  machine_type = var.machine_type
  zone         = "${var.region}-b"

  # Allow stopping for updates (required for machine_type changes)
  allow_stopping_for_update = true

  # Advanced machine features for custom memory
  advanced_machine_features {
    enable_nested_virtualization = false
  }

  boot_disk {
    initialize_params {
      image = "web1-prod-image-v3"  # Use new image with correct configuration
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    network    = "default"
    subnetwork = "default"
    access_config {
      nat_ip = google_compute_address.web1_static_ip.address
    }
    network_ip = google_compute_address.web1_internal_ip.address
  }

  metadata = {
    ssh-keys = var.ssh_public_key
  }

  # NO startup script - configuration is set as default in the image
  # Nginx configuration is already set as default and will work correctly

  tags = ["web-server"]

  depends_on = [
    google_compute_address.web1_static_ip,
    google_compute_address.web1_internal_ip
  ]
}

# Web Server 2
resource "google_compute_instance" "web2" {
  name         = "web2-${var.environment}"
  machine_type = var.machine_type
  zone         = "${var.region}-b"

  # Allow stopping for updates (required for machine_type changes)
  allow_stopping_for_update = true

  # Advanced machine features for custom memory
  advanced_machine_features {
    enable_nested_virtualization = false
  }

  boot_disk {
    initialize_params {
      image = "web2-prod-image-v3"  # Use new image with correct configuration
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    network    = "default"
    subnetwork = "default"
    access_config {
      nat_ip = google_compute_address.web2_static_ip.address
    }
    network_ip = google_compute_address.web2_internal_ip.address
  }

  metadata = {
    ssh-keys = var.ssh_public_key
  }

  # NO startup script - configuration is set as default in the image
  # Nginx configuration is already set as default and will work correctly

  tags = ["web-server"]

  depends_on = [
    google_compute_address.web2_static_ip,
    google_compute_address.web2_internal_ip
  ]
}
