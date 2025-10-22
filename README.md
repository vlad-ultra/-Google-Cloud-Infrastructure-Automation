# 🚀 Google Cloud Infrastructure Automation

## 📋 Project Overview

This project provides a complete **DevOps automation solution** for deploying and managing a highly available web infrastructure on Google Cloud Platform (GCP). The system features ultra-fast deployment using pre-configured images, cost-effective e2-micro instances, centralized SSL certificate management, and automated load balancing.

## ✨ Key Features

- **⚡ Ultra-Fast Deployment** - Deploy infrastructure in ~30-60 seconds using pre-configured images
- **💰 Cost-Effective** - Uses e2-micro instances (1 vCPU, 1GB RAM) for portfolio projects
- **🔄 Automatic Content Sync** - Automatically applies HTML content from `web-apps/` directory
- **🔐 Centralized SSL Management** - Manage Let's Encrypt certificates through Google Cloud Storage
- **⚖️ Load Balancing** - HAProxy with health checks and SSL termination
- **🖼️ Custom Images** - Pre-configured images with all settings preserved
- **🔧 Configuration Management** - Automated configuration backup and restore
- **📊 Monitoring** - Built-in load balancing tests and health checks
- **🚀 GitHub Actions CI/CD** - Automated deployment and testing workflows

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

### Option 1: GitHub Actions (Recommended)

1. **Fork this repository**
2. **Set up GitHub Secrets**:
   - Go to Settings → Secrets and variables → Actions
   - Add `GCP_SA_KEY` (your service account JSON key)
   - Add `GCP_PROJECT_ID` (your GCP project ID)
3. **Deploy Infrastructure**:
   - Go to Actions → "Build and Deploy Infrastructure"
   - Click "Run workflow" → Select `prod` → Type `YES` → Run
4. **Test your deployment**:
   - Visit https://balancer.svdevops.tech
   - Check load balancing with the testing commands below

### Option 2: Local Deployment

#### Prerequisites

1. **Google Cloud SDK** installed and configured
2. **Terraform** installed
3. **Git** for version control
4. **SSH key** for server access

#### 1. Clone the Repository

```bash
git clone https://github.com/vlad-ultra/-Google-Cloud-Infrastructure-Automation.git
cd Google-Cloud-Infrastructure-Automation
```

#### 2. Configure Google Cloud

```bash
# Authenticate with Google Cloud
gcloud auth login

# Set your project ID
gcloud config set project YOUR_PROJECT_ID

# Enable required APIs
gcloud services enable compute.googleapis.com
gcloud services enable dns.googleapis.com
```

#### 3. Deploy Infrastructure

```bash
# Deploy with automatic content sync from web-apps/
./deploy.sh
```

The `deploy.sh` script automatically:
- Deploys infrastructure using pre-configured images
- Applies HTML content from `web-apps/` directory to all servers
- Configures HAProxy with correct IP addresses
- Tests load balancing functionality

#### 4. Test Your Deployment

```bash
# Test load balancing (should alternate between Web1 and Web2)
for i in {1..10}; do
  echo "Request $i:"
  curl -s https://balancer.svdevops.tech | grep -o "Web Server [12]"
  sleep 1
done

# Test individual servers
curl -s https://web1.svdevops.tech
curl -s https://web2.svdevops.tech

# Test HAProxy stats
curl -s https://balancer.svdevops.tech/stats
```

#### 5. Update Content

To update content, simply:
1. Edit HTML files in `web-apps/` directory
2. Run `./deploy.sh` again
3. Content will be automatically applied to all servers

## 📁 Project Structure

```
📁 GoogleCloud/first-project/
├── 🚀 deploy.sh                    # Main deployment script with content sync
├── 🗑️ destroy.sh                   # Infrastructure destruction wrapper
├── 📁 infrastructure/              # Terraform configurations
│   ├── main.tf                     # Main Terraform config
│   ├── variables.tf                # Variables
│   ├── outputs.tf                  # Outputs
│   ├── haproxy.tf                  # HAProxy instance
│   ├── web-servers.tf              # Web servers
│   ├── static-ips.tf               # Static IP addresses
│   ├── static-internal-ips.tf      # Internal IP addresses
│   └── firewall.tf                 # Firewall rules
├── 📁 scripts/                     # Organized utility scripts
│   ├── deployment/                 # Deployment scripts
│   │   ├── deploy.sh              # Core deployment logic
│   │   ├── destroy-infrastructure.sh # Infrastructure destruction
│   │   └── ultra-fast-deploy.sh   # Fast deployment option
│   ├── management/                 # Management scripts
│   │   ├── apply-configs.sh       # Apply configurations
│   │   ├── create-new-images.sh   # Create custom images
│   │   └── restore-configs.sh     # Restore configurations
│   ├── ssl/                       # SSL certificate management
│   │   ├── ssl-manager.sh         # Interactive SSL manager
│   │   ├── export-certs-to-gcs.sh # Export certificates to GCS
│   │   ├── import-certs-from-gcs.sh # Import certificates from GCS
│   │   ├── create-images-with-gcs-certs.sh # Create images with GCS certs
│   │   └── ssl.sh                 # SSL wrapper script
│   ├── testing/                   # Testing scripts
│   │   └── test-load-balancing.sh # Load balancing tests
│   ├── configure-haproxy.sh       # HAProxy configuration
│   └── update-content.sh          # Content updates
├── 📁 web-apps/                    # Web server content (auto-synced)
│   ├── web1.html                   # Web1 HTML content
│   ├── web2.html                   # Web2 HTML content
│   └── haproxy.html                # HAProxy dashboard content
├── 📁 backups/                     # Configuration backups
│   └── current-state/              # Current state backups
│       ├── haproxy.cfg             # HAProxy configuration
│       ├── web1-nginx.conf         # Web1 Nginx configuration
│       ├── web2-nginx.conf         # Web2 Nginx configuration
│       ├── web1-content.html       # Web1 content backup
│       └── web2-content.html        # Web2 content backup
└── 📄 README.md                    # This file
```

## 🔧 Scripts Overview

### Main Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| `deploy.sh` | Deploy infrastructure + auto-sync content from web-apps/ | `./deploy.sh` |
| `destroy.sh` | Destroy infrastructure (preserves static IPs) | `./destroy.sh` |

### Deployment Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| `scripts/deployment/deploy.sh` | Core deployment logic with content sync | `./scripts/deployment/deploy.sh` |
| `scripts/deployment/destroy-infrastructure.sh` | Infrastructure destruction | `./scripts/deployment/destroy-infrastructure.sh` |
| `scripts/deployment/ultra-fast-deploy.sh` | Fast deployment option | `./scripts/deployment/ultra-fast-deploy.sh` |

### Management Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| `scripts/management/apply-configs.sh` | Apply configurations to existing servers | `./scripts/management/apply-configs.sh` |
| `scripts/management/create-new-images.sh` | Create new images with current configurations | `./scripts/management/create-new-images.sh` |
| `scripts/management/restore-configs.sh` | Restore configurations from backups | `./scripts/management/restore-configs.sh` |

### SSL Management

| Script | Purpose | Usage |
|--------|---------|-------|
| `scripts/ssl/ssl-manager.sh` | Interactive SSL management | `./scripts/ssl/ssl-manager.sh` |
| `scripts/ssl/ssl.sh` | SSL wrapper script | `./scripts/ssl/ssl.sh` |
| `scripts/ssl/export-certs-to-gcs.sh` | Export certificates to GCS | `./scripts/ssl/export-certs-to-gcs.sh` |
| `scripts/ssl/import-certs-from-gcs.sh` | Import certificates from GCS | `./scripts/ssl/import-certs-from-gcs.sh` |

### Testing Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| `scripts/testing/test-load-balancing.sh` | Test load balancing functionality | `./scripts/testing/test-load-balancing.sh` |

## 🔐 SSL Certificate Management

### Using SSL Manager (Recommended)

```bash
# Interactive SSL management
./scripts/ssl/ssl.sh
```

### Manual SSL Operations

```bash
# Export certificates to GCS
cd scripts/ssl
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
   ./scripts/management/apply-configs.sh
   ```

2. **Create new images:**
   ```bash
   ./scripts/management/create-new-images.sh
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
./scripts/management/restore-configs.sh
```

### Apply Custom Configurations

```bash
# Apply configurations to existing servers
./scripts/management/apply-configs.sh
```

## 🌐 Live URLs and Testing

After deployment, the following URLs will be available for testing:

### 🔗 Production URLs

| Service | URL | Description |
|---------|-----|-------------|
| **Load Balancer** | https://balancer.svdevops.tech | Main entry point with load balancing |
| **Web Server 1** | https://web1.svdevops.tech | Direct access to Web Server 1 |
| **Web Server 2** | https://web2.svdevops.tech | Direct access to Web Server 2 |
| **HAProxy Stats** | https://balancer.svdevops.tech/stats | Load balancer statistics dashboard |

### 🧪 Testing Commands

#### Test Load Balancing
```bash
# Test load balancing (should alternate between Web1 and Web2)
for i in {1..10}; do
  echo "Request $i:"
  curl -s https://balancer.svdevops.tech | grep -o "Web Server [12]"
  sleep 1
done
```

#### Test Individual Servers
```bash
# Test Web Server 1 directly
curl -s https://web1.svdevops.tech

# Test Web Server 2 directly  
curl -s https://web2.svdevops.tech

# Test HAProxy stats
curl -s https://balancer.svdevops.tech/stats
```

#### Test SSL Certificates
```bash
# Check SSL certificate validity
openssl s_client -connect balancer.svdevops.tech:443 -servername balancer.svdevops.tech < /dev/null 2>/dev/null | openssl x509 -noout -dates

# Test HTTPS redirect
curl -I http://balancer.svdevops.tech
# Should return 301 redirect to HTTPS
```

#### Test Health Checks
```bash
# Check if all services are responding
echo "Testing all endpoints..."
curl -s -o /dev/null -w "Load Balancer: %{http_code}\n" https://balancer.svdevops.tech
curl -s -o /dev/null -w "Web1: %{http_code}\n" https://web1.svdevops.tech  
curl -s -o /dev/null -w "Web2: %{http_code}\n" https://web2.svdevops.tech
```

### 📊 Expected Test Results

- **Load Balancer**: Should return alternating "Web Server 1" and "Web Server 2" responses
- **Individual Servers**: Should return consistent "Web Server 1" or "Web Server 2" respectively
- **SSL Certificates**: Should be valid Let's Encrypt certificates
- **HTTP Redirect**: Should redirect to HTTPS (301 status)
- **Health Checks**: All endpoints should return 200 status code

## 🔄 Content Synchronization

### Automatic Content Sync

The `deploy.sh` script automatically applies content from the `web-apps/` directory to all servers:

- **web1.html** → Web Server 1
- **web2.html** → Web Server 2  
- **haproxy.html** → HAProxy dashboard

### Manual Content Update

To update content without redeploying infrastructure:

```bash
# Update content on all servers
./scripts/update-content.sh
```

### Content Workflow

1. **Edit HTML files** in `web-apps/` directory
2. **Run deploy script** - content is automatically applied
3. **Test changes** using the testing scripts

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
- **Server Type:** e2-micro (1 vCPU, 1GB RAM) - cost-effective for portfolio projects
- **Load Balancing:** Round-robin with health checks
- **SSL:** Let's Encrypt with automatic renewal

## 🔒 Security Features

- **SSL/TLS Encryption** - All traffic encrypted
- **Firewall Rules** - Restricted access to necessary ports
- **Static IPs** - Fixed IP addresses for stability
- **Health Checks** - Automatic failover for failed servers

## 🚀 GitHub Actions CI/CD

The project includes automated deployment and testing via GitHub Actions workflows:

### 📋 Available Workflows

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| **Build and Deploy Infrastructure** | Manual | Deploy/update infrastructure with content sync |
| **Remove GCP Deploy** | Manual | Destroy infrastructure (preserves static IPs) |
| **Test Infrastructure** | Manual | Comprehensive infrastructure testing |

### 🔧 Workflow Features

#### Build and Deploy Infrastructure
- **Authentication**: Google Cloud service account
- **Infrastructure**: Terraform deployment with existing resource import
- **Content Sync**: Automatic application of `web-apps/` content
- **Testing**: Load balancing verification
- **Time**: ~30-60 seconds deployment

#### Test Infrastructure
- **Connectivity Tests**: HTTP/HTTPS for all servers
- **Load Balancing Tests**: Round-robin verification
- **Domain Tests**: Full domain connectivity testing
- **Health Checks**: Instance status verification
- **Test Types**: `connectivity`, `full`, `quick`

#### Remove GCP Deploy
- **Safe Destruction**: Preserves static IPs and custom images
- **Verification**: Confirms complete removal
- **Error Handling**: Shows red status on failures

### 🛠️ Setup Required

1. **GitHub Secrets**:
   ```
   GCP_SA_KEY: Your Google Cloud Service Account JSON key
   GCP_PROJECT_ID: Your GCP project ID
   ```

2. **Service Account Permissions**:
   - `roles/compute.instanceAdmin`
   - `roles/compute.networkAdmin`
   - `roles/dns.admin`
   - `roles/storage.admin`
   - `roles/compute.securityAdmin`

### 🚀 How to Use GitHub Actions

1. **Deploy Infrastructure**:
   - Go to Actions → "Build and Deploy Infrastructure"
   - Click "Run workflow"
   - Select environment: `prod` or `staging`
   - Type `YES` to confirm
   - Click "Run workflow"

2. **Test Infrastructure**:
   - Go to Actions → "Test Infrastructure"
   - Click "Run workflow"
   - Select test type: `connectivity`, `full`, or `quick`
   - Select environment: `prod` or `staging`
   - Click "Run workflow"

3. **Remove Infrastructure**:
   - Go to Actions → "Remove GCP Deploy"
   - Click "Run workflow"
   - Type `DESTROY` to confirm
   - Choose whether to preserve IPs
   - Click "Run workflow"

## 💡 Usage Examples

### 🎯 Portfolio Website Deployment

Perfect for showcasing your DevOps skills:

```bash
# 1. Deploy infrastructure
# Via GitHub Actions: Go to Actions → "Build and Deploy Infrastructure" → Run
# Or locally: ./deploy.sh

# 2. Update your portfolio content
echo "<h1>My DevOps Portfolio</h1><p>Infrastructure deployed with Terraform + GitHub Actions</p>" > web-apps/web1.html
echo "<h1>Load Balanced Portfolio</h1><p>High availability with HAProxy</p>" > web-apps/web2.html

# 3. Deploy changes
./deploy.sh

# 4. Test your live site
curl https://balancer.svdevops.tech
```

### 🔄 CI/CD Pipeline Demo

Showcase automated deployment:

1. **Make changes** to `web-apps/` files
2. **Commit and push** to GitHub
3. **Trigger deployment** via GitHub Actions
4. **Verify changes** are live automatically

### 🧪 Load Balancing Demo

Demonstrate high availability:

```bash
# Show load balancing in action
while true; do
  echo "$(date): $(curl -s https://balancer.svdevops.tech | grep -o 'Web Server [12]')"
  sleep 2
done
```

### 📊 Monitoring Demo

Show infrastructure monitoring:

```bash
# Check HAProxy stats
curl -s https://balancer.svdevops.tech/stats | grep -A 10 "Backend servers"

# Test health checks
curl -s -o /dev/null -w "Load Balancer: %{http_code}\n" https://balancer.svdevops.tech
curl -s -o /dev/null -w "Web1: %{http_code}\n" https://web1.svdevops.tech
curl -s -o /dev/null -w "Web2: %{http_code}\n" https://web2.svdevops.tech
```

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