# Variables for High Availability Load Balancer Infrastructure

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "europe-west1"
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "europe-west1-b"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "machine_type" {
  description = "Machine type for VMs"
  type        = string
  default     = "e2-standard-2"  # 2 vCPU, 4GB RAM - much faster than e2-micro
}

variable "machine_memory" {
  description = "Machine memory in GB"
  type        = number
  default     = 4  # 4GB RAM instead of default 8GB
}

variable "web_server_count" {
  description = "Number of web servers"
  type        = number
  default     = 2
}

variable "network_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/24"
}

variable "web_server_ips" {
  description = "Internal IPs for web servers"
  type        = list(string)
  default     = ["10.0.0.10", "10.0.0.11"]
}

variable "haproxy_ip" {
  description = "Internal IP for HAProxy"
  type        = string
  default     = "10.0.0.12"
}

variable "ssh_user" {
  description = "SSH username"
  type        = string
  default     = "vladultra777"
}

variable "ssh_public_key" {
  description = "SSH public key content"
  type        = string
  default     = ""
}
