# 🚀 Google Cloud Infrastructure Automation

## 📋 Project Overview

This project provides a complete **DevOps automation solution** for deploying and managing a highly available web infrastructure on Google Cloud Platform (GCP). The system features ultra-fast deployment using pre-configured images, centralized SSL certificate management, and automated load balancing.

## ✨ Key Features

- **⚡ Ultra-Fast Deployment** - Deploy infrastructure in ~30-60 seconds using pre-configured images
- **🔄 Automatic Content Sync** - Automatically applies HTML content from `web-apps/` directory
- **🔐 Centralized SSL Management** - Manage Let's Encrypt certificates through Google Cloud Storage
- **⚖️ Load Balancing** - HAProxy with health checks and SSL termination
- **🖼️ Custom Images** - Pre-configured images with all settings preserved
- **🔧 Configuration Management** - Automated configuration backup and restore
- **📊 Monitoring** - Built-in load balancing tests and health checks

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   HAProxy LB    │    │   Web Server 1  │    │   Web Server 2  │
│  (Load Balancer)│    │   (Nginx)       │    │   (Nginx)       │
│                 │    │                 │    │                 │
│ • SSL Termination│◄──►│ • HTTP/HTTPS    │    │ • HTTP/HTTPS    │
│ • Health Checks │    │ • Let's Encrypt │    │ • Let's Encrypt │
│ • Stats Page    │    │ • Custom Content│    │ • Custom Content│
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │  Google Cloud   │
                    │   Storage       │
                    │                 │
                    │ • SSL Certs     │
                    │ • Images        │
                    │ • Backups       │
                    └─────────────────┘
```

## 🚀 Quick Start

### Prerequisites

1. **Google Cloud SDK** installed and configured
2. **Terraform** installed
3. **Git** for version control
4. **SSH key** for server access

### 1. Clone the Repository

```bash
git clone https://github.com/vlad-ultra/-Google-Cloud-Infrastructure-Automation.git
cd Google-Cloud-Infrastructure-Automation
```

### 2. Configure Google Cloud

```bash
# Authenticate with Google Cloud
gcloud auth login

# Set your project ID
gcloud config set project YOUR_PROJECT_ID

# Enable required APIs
gcloud services enable compute.googleapis.com
gcloud services enable dns.googleapis.com
```

### 3. Deploy Infrastructure

```bash
# Deploy with automatic content sync from web-apps/
./deploy.sh
```

The `deploy.sh` script automatically:
- Deploys infrastructure using pre-configured images
- Applies HTML content from `web-apps/` directory to all servers
- Configures HAProxy with correct IP addresses
- Tests load balancing functionality

### 4. Update Content

To update content, simply:
1. Edit HTML files in `web-apps/` directory
2. Run `./deploy.sh` again
3. Choose option 2 to update content only

## 📁 Project Structure

```
📁 GoogleCloud/first-project/
├── 🚀 deploy.sh                    # Main deployment script
├── 🗑️ destroy-infrastructure.sh    # Infrastructure destruction
├── 🔧 apply-configs.sh             # Apply configurations
├── 🔄 test-load-balancing.sh       # Load balancing tests
├── 🖼️ create-new-images.sh         # Create custom images
├── 🔧 restore-configs.sh           # Restore configurations
├── 🔐 ssl.sh                       # SSL management
├── 📁 infrastructure/              # Terraform configurations
│   ├── main.tf                     # Main Terraform config
│   ├── variables.tf                # Variables
│   ├── outputs.tf                  # Outputs
│   ├── haproxy.tf                  # HAProxy instance
│   ├── web-servers.tf              # Web servers
│   ├── static-ips.tf               # Static IP addresses
│   ├── static-internal-ips.tf      # Internal IP addresses
│   └── firewall.tf                 # Firewall rules
├── 📁 scripts/                     # Utility scripts
│   ├── configure-haproxy.sh        # HAProxy configuration
│   └── update-content.sh           # Content updates
├── 📁 ssl-management/              # SSL certificate management
│   ├── ssl-manager.sh              # Interactive SSL manager
│   ├── export-certs-to-gcs.sh      # Export certificates to GCS
│   ├── import-certs-from-gcs.sh    # Import certificates from GCS
│   └── create-images-with-gcs-certs.sh # Create images with GCS certs
├── 📁 backups/                     # Configuration backups
│   └── current-state/              # Current state backups
│       ├── haproxy.cfg             # HAProxy configuration
│       ├── web1-nginx.conf         # Web1 Nginx configuration
│       ├── web2-nginx.conf         # Web2 Nginx configuration
│       ├── web1-content.html       # Web1 content
│       └── web2-content.html       # Web2 content
├── 📁 web-apps/                    # Web server content
│   ├── web1.html                   # Web1 HTML content
│   ├── web2.html                   # Web2 HTML content
│   └── haproxy.html                # HAProxy content
└── 📄 README.md                    # This file
```

## 🔧 Scripts Overview

### Main Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| `deploy.sh` | Deploy infrastructure + apply content from web-apps/ | `./deploy.sh` |
| `destroy.sh` | Destroy infrastructure (preserves static IPs) | `./destroy.sh` |
| `test.sh` | Test load balancing functionality | `./test.sh` |

### Image Management

| Script | Purpose | Usage |
|--------|---------|-------|
| `create-new-images.sh` | Create new images with current configurations | `./create-new-images.sh` |
| `ssl.sh` | Interactive SSL management | `./ssl.sh` |

### Configuration Management

| Script | Purpose | Usage |
|--------|---------|-------|
| `restore-configs.sh` | Restore configurations from backups | `./restore-configs.sh` |

## 🔐 SSL Certificate Management

### Using SSL Manager (Recommended)

```bash
# Interactive SSL management
./ssl.sh
```

### Manual SSL Operations

```bash
# Export certificates to GCS
cd ssl-management
./export-certs-to-gcs.sh

# Import certificates from GCS
./import-certs-from-gcs.sh

# Create images with GCS certificates
./create-images-with-gcs-certs.sh
```

## 🖼️ Image Management

### Creating New Images

1. **Apply current configurations:**
   ```bash
   ./apply-configs.sh
   ```

2. **Create new images:**
   ```bash
   ./create-new-images.sh
   ```

3. **Update Terraform to use new images:**
   - Edit `infrastructure/haproxy.tf`
   - Edit `infrastructure/web-servers.tf`
   - Update image names to new versions

### Image Versions

- **v3** - Current production images with correct configurations
- **v4** - Images with GCS certificates (when created)

## ⚙️ Configuration Management

### Backup Current State

```bash
# Configurations are automatically backed up in backups/current-state/
```

### Restore Configurations

```bash
# Restore from backups
./restore-configs.sh
```

### Apply Custom Configurations

```bash
# Apply configurations to existing servers
./apply-configs.sh
```

## 🌐 URLs and Access

After deployment, the following URLs will be available:

- **Load Balancer:** https://balancer.svdevops.tech
- **Web Server 1:** https://web1.svdevops.tech
- **Web Server 2:** https://web2.svdevops.tech
- **HAProxy Stats:** http://[HAProxy_IP]:8080/stats

## 🔧 Troubleshooting

### Common Issues

1. **Load Balancer not responding:**
   ```bash
   # Check HAProxy status
   gcloud compute ssh haproxy-prod --zone=europe-west1-b --command="sudo systemctl status haproxy"
   ```

2. **SSL certificates not working:**
   ```bash
   # Check certificate status
   ./ssl.sh
   # Select option 6: Test certificate validity
   ```

3. **Web servers not responding:**
   ```bash
   # Check Nginx status
   gcloud compute ssh web1-prod --zone=europe-west1-b --command="sudo systemctl status nginx"
   ```

### Logs

```bash
# HAProxy logs
gcloud compute ssh haproxy-prod --zone=europe-west1-b --command="sudo journalctl -u haproxy -f"

# Nginx logs
gcloud compute ssh web1-prod --zone=europe-west1-b --command="sudo journalctl -u nginx -f"
```

## 📊 Performance

- **Deployment Time:** ~30-60 seconds
- **Server Type:** e2-standard-2 (2 vCPU, 4GB RAM)
- **Load Balancing:** Round-robin with health checks
- **SSL:** Let's Encrypt with automatic renewal

## 🔒 Security Features

- **SSL/TLS Encryption** - All traffic encrypted
- **Firewall Rules** - Restricted access to necessary ports
- **Static IPs** - Fixed IP addresses for stability
- **Health Checks** - Automatic failover for failed servers

## 🚀 GitHub Actions CI/CD

The project includes GitHub Actions workflows for:

- **Automated Deployment** - Deploy on push to main
- **Content Updates** - Update web content
- **Monitoring** - Health checks and monitoring

## 📝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👨‍💻 Author

**Vlad Stadnyk** - DevOps Engineer
- GitHub: [@vlad-ultra](https://github.com/vlad-ultra)
- Project: Google Cloud Infrastructure Automation

## 🙏 Acknowledgments

- Google Cloud Platform for infrastructure
- Terraform for Infrastructure as Code
- HAProxy for load balancing
- Let's Encrypt for SSL certificates
- Nginx for web serving

---

**🎯 Ready for Production** - This infrastructure is production-ready and can handle real-world traffic with high availability and performance.