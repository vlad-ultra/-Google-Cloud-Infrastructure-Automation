# Terraform Variables Configuration

# Required: Your GCP Project ID
project_id = "fair-plasma-475719-g7"

# Optional: Region and Zone (defaults to Europe)
region = "europe-west1"
zone   = "europe-west1-b"

# Optional: Environment name
environment = "prod"

# Optional: Machine type - UPGRADED for faster deployment
machine_type = "e2-standard-2"  # 2 vCPU, 8GB RAM - much faster than e2-micro
machine_memory = 4  # 4GB RAM instead of default 8GB

# Optional: Number of web servers (default: 2)
web_server_count = 2

# Optional: Network configuration
network_cidr = "10.0.0.0/24"

# Optional: Internal IPs for servers (updated with correct IPs)
web_server_ips = ["10.132.15.221", "10.132.15.222"]
haproxy_ip     = "10.132.15.223"
