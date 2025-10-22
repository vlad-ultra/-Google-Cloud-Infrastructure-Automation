# Web Servers using pre-built images

# Web Server 1 - Using pre-built image with Nginx
resource "google_compute_instance" "web1" {
  name         = "web1-${var.environment}"
  machine_type = var.machine_type
  zone         = var.zone
  
  # Custom memory configuration
  advanced_machine_features {
    enable_nested_virtualization = false
  }

  boot_disk {
    initialize_params {
      image = "web-server-1-image"
      size  = 20
    }
  }

  network_interface {
    network = "default"
    network_ip = google_compute_address.web1_internal_ip.address
    access_config {
      nat_ip = google_compute_address.web1_static_ip.address
    }
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${var.ssh_public_key}"
  }

  tags = ["web-server", "ssh-server"]

  # Minimal startup script - just ensure nginx is running
  metadata_startup_script = <<-EOF
    #!/bin/bash
    # Ensure nginx is running
    systemctl start nginx
    systemctl enable nginx
  EOF
}

# Web Server 2 - Using pre-built image with Nginx
resource "google_compute_instance" "web2" {
  name         = "web2-${var.environment}"
  machine_type = var.machine_type
  zone         = var.zone
  
  # Custom memory configuration
  advanced_machine_features {
    enable_nested_virtualization = false
  }

  boot_disk {
    initialize_params {
      image = "web-server-2-image"
      size  = 20
    }
  }

  network_interface {
    network = "default"
    network_ip = google_compute_address.web2_internal_ip.address
    access_config {
      nat_ip = google_compute_address.web2_static_ip.address
    }
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${var.ssh_public_key}"
  }

  tags = ["web-server", "ssh-server"]

  # Minimal startup script - just ensure nginx is running
  metadata_startup_script = <<-EOF
    #!/bin/bash
    # Ensure nginx is running
    systemctl start nginx
    systemctl enable nginx
  EOF
}