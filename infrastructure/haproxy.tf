# HAProxy Load Balancer using pre-built image

resource "google_compute_instance" "haproxy" {
  name         = "haproxy-${var.environment}"
  machine_type = var.machine_type
  zone         = var.zone

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
    ssh-keys = "${var.ssh_user}:${file(var.ssh_public_key_path)}"
  }

  tags = ["load-balancer", "ssh-server"]

  # Minimal startup script - just ensure haproxy is running
  metadata_startup_script = <<-EOF
    #!/bin/bash
    # Ensure haproxy is running
    systemctl start haproxy
    systemctl enable haproxy
  EOF
}