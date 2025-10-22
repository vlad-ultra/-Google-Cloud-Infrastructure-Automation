# HAProxy Load Balancer Instance
resource "google_compute_instance" "haproxy" {
  name         = "haproxy-${var.environment}"
  machine_type = var.machine_type
  zone         = "${var.region}-b"

  # Advanced machine features for custom memory
  advanced_machine_features {
    enable_nested_virtualization = false
  }

  boot_disk {
    initialize_params {
      image = "haproxy-prod-image-v3"  # Use new image with correct configuration
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    network    = "default"
    subnetwork = "default"
    access_config {
      nat_ip = google_compute_address.haproxy_static_ip.address
    }
    network_ip = google_compute_address.haproxy_internal_ip.address
  }

  metadata = {
    ssh-keys = var.ssh_public_key
  }

  # NO startup script - configuration is set as default in the image
  # HAProxy configuration is already set as default and will work correctly

  tags = ["load-balancer", "web-server"]

  depends_on = [
    google_compute_address.haproxy_static_ip,
    google_compute_address.haproxy_internal_ip
  ]
}
