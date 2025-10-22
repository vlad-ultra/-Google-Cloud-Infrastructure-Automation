# 🚀 Google Cloud Infrastructure Automation

> **Professional DevOps automation solution for deploying highly available web infrastructure on Google Cloud Platform**

[![GitHub Actions](https://img.shields.io/badge/GitHub%20Actions-Ready-brightgreen)](https://github.com/vlad-ultra/-Google-Cloud-Infrastructure-Automation/actions)
[![Terraform](https://img.shields.io/badge/Terraform-Infrastructure%20as%20Code-blue)](https://terraform.io)
[![Google Cloud](https://img.shields.io/badge/Google%20Cloud-Platform-orange)](https://cloud.google.com)
[![HAProxy](https://img.shields.io/badge/HAProxy-Load%20Balancer-red)](https://haproxy.org)
[![Nginx](https://img.shields.io/badge/Nginx-Web%20Server-green)](https://nginx.org)

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

## 🚀 Production Deployment

### GitHub Actions Workflows

This project uses **GitHub Actions** for automated deployment and management. All workflows are configured for the `production` branch.

#### Available Workflows

| Workflow | Purpose | Trigger |
|----------|---------|---------|
| **🚀 Build and Deploy Infrastructure** | Deploy/update infrastructure with content sync | Manual |
| **🗑️ Destroy Infrastructure** | Destroy infrastructure (preserves static IPs) | Manual |
| **🧪 Test Infrastructure** | Comprehensive infrastructure testing | Manual |
| **📊 Monitor Infrastructure** | Health checks and monitoring | Manual |
| **🔄 Update Content** | Update web content without redeployment | Manual |

#### How to Deploy

1. **Go to GitHub Actions**:
   - Navigate to Actions tab in this repository
   - Select "🚀 Build and Deploy Infrastructure"
   - Click "Run workflow"

2. **Configure deployment**:
   - Select branch: `production`
   - Environment: `prod`
   - Type `YES` to confirm deployment

3. **Monitor deployment**:
   - Watch the workflow progress in real-time
   - Deployment takes ~30-60 seconds
   - All content from `web-apps/` is automatically applied

#### Test Your Deployment

After deployment, test these URLs:

- **Load Balancer**: [https://balancer.svdevops.tech](https://balancer.svdevops.tech)
- **Web Server 1**: [https://web1.svdevops.tech](https://web1.svdevops.tech)
- **Web Server 2**: [https://web2.svdevops.tech](https://web2.svdevops.tech)
- **HAProxy Stats**: [https://balancer.svdevops.tech/stats](https://balancer.svdevops.tech/stats)

#### Load Balancing Test

```bash
# Test load balancing (should alternate between Web1 and Web2)
for i in {1..10}; do
  echo "Request $i:"
  curl -s https://balancer.svdevops.tech | grep -o "Web Server [12]"
  sleep 1
done
```

#### Update Content

To update web content:
1. Edit HTML files in `web-apps/` directory
2. Commit and push to `production` branch
3. Run "🔄 Update Content" workflow
4. Content is automatically applied to all servers

## 📁 Project Structure

```
📁 Google-Cloud-Infrastructure-Automation/
├── 🚀 deploy.sh                    # Main deployment script
├── 🗑️ destroy.sh                   # Main destruction script
├── 📄 README.md                    # This documentation
├── 📁 .github/workflows/           # GitHub Actions workflows
│   ├── 🚀 deploy.yml               # Build and Deploy Infrastructure
│   ├── 🧪 test-workflow.yml        # Test Infrastructure
│   ├── 📊 monitor.yml              # Monitor Infrastructure
│   ├── 🔄 update-content.yml       # Update Content
│   ├── 🗑️ destroy.yml              # Destroy Infrastructure
│   └── 🐛 debug-auth.yml           # Debug Authentication
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
│   ├── management/                 # Management scripts
│   ├── ssl/                       # SSL certificate management
│   └── testing/                   # Testing scripts
├── 📁 web-apps/                    # Web server content (auto-synced)
│   ├── web1.html                   # Web Server 1 content
│   ├── web2.html                   # Web Server 2 content
│   └── haproxy.html                # HAProxy dashboard content
└── 📁 configs/                     # Configuration backups
    └── current-state/              # Current configuration state
        ├── haproxy.cfg             # HAProxy configuration
        ├── web1-nginx.conf         # Web1 Nginx configuration
        └── web2-nginx.conf         # Web2 Nginx configuration
```

## 🌐 Live URLs and Testing

### 🔗 Production URLs

| Service | URL | Description |
|---------|-----|-------------|
| **Load Balancer** | [https://balancer.svdevops.tech](https://balancer.svdevops.tech) | Main entry point with load balancing |
| **Web Server 1** | [https://web1.svdevops.tech](https://web1.svdevops.tech) | Direct access to Web Server 1 |
| **Web Server 2** | [https://web2.svdevops.tech](https://web2.svdevops.tech) | Direct access to Web Server 2 |
| **HAProxy Stats** | [https://balancer.svdevops.tech/stats](https://balancer.svdevops.tech/stats) | Load balancer statistics dashboard |

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

## 🔄 Content Management

### Automatic Content Sync

The deployment workflow automatically applies content from the `web-apps/` directory to all servers:

- **web1.html** → Web Server 1
- **web2.html** → Web Server 2  
- **haproxy.html** → HAProxy dashboard

### Manual Content Update

To update content without redeploying infrastructure:

1. Edit HTML files in `web-apps/` directory
2. Commit and push to `production` branch
3. Run "🔄 Update Content" workflow
4. Content is automatically applied to all servers

## 🚀 GitHub Actions CI/CD

### Workflow Features

#### 🚀 Build and Deploy Infrastructure
- **Authentication**: Google Cloud service account
- **Infrastructure**: Terraform deployment with existing resource import
- **Content Sync**: Automatic application of `web-apps/` content
- **Testing**: Load balancing verification
- **Time**: ~30-60 seconds deployment

#### 🧪 Test Infrastructure
- **Connectivity Tests**: HTTP/HTTPS for all servers
- **Load Balancing Tests**: Round-robin verification
- **Domain Tests**: Full domain connectivity testing
- **Health Checks**: Instance status verification
- **Test Types**: `connectivity`, `full`, `quick`

#### 🗑️ Destroy Infrastructure
- **Safe Destruction**: Preserves static IPs and custom images
- **Verification**: Confirms complete removal
- **Error Handling**: Shows red status on failures

#### 📊 Monitor Infrastructure
- **Health Checks**: Instance and service status
- **Domain Testing**: All production URLs
- **Alerting**: Notifications on failures
- **Reporting**: Detailed status reports

#### 🔄 Update Content
- **Content Sync**: Updates web content only
- **No Infrastructure Changes**: Preserves existing setup
- **Fast Updates**: Quick content deployment

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
   - Go to Actions → "🚀 Build and Deploy Infrastructure"
   - Click "Run workflow"
   - Select branch: `production`
   - Select environment: `prod`
   - Type `YES` to confirm
   - Click "Run workflow"

2. **Test Infrastructure**:
   - Go to Actions → "🧪 Test Infrastructure"
   - Click "Run workflow"
   - Select test type: `connectivity`, `full`, or `quick`
   - Select environment: `prod`
   - Click "Run workflow"

3. **Update Content**:
   - Go to Actions → "🔄 Update Content"
   - Click "Run workflow"
   - Content is automatically updated

4. **Monitor Infrastructure**:
   - Go to Actions → "📊 Monitor Infrastructure"
   - Click "Run workflow"
   - View health status and reports

5. **Remove Infrastructure**:
   - Go to Actions → "🗑️ Destroy Infrastructure"
   - Click "Run workflow"
   - Type `DESTROY` to confirm
   - Choose whether to preserve IPs
   - Click "Run workflow"

## 💡 Usage Examples

### 🎯 Portfolio Website Deployment

Perfect for showcasing your DevOps skills:

1. **Deploy infrastructure** via GitHub Actions
2. **Update your portfolio content** in `web-apps/` files
3. **Deploy changes** via "🔄 Update Content" workflow
4. **Test your live site** at [https://balancer.svdevops.tech](https://balancer.svdevops.tech)

### 🔄 CI/CD Pipeline Demo

Showcase automated deployment:

1. **Make changes** to `web-apps/` files
2. **Commit and push** to `production` branch
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

## 🔧 Troubleshooting

### Common Issues

1. **Load Balancer not responding**:
   - Check HAProxy status via Monitor workflow
   - Verify firewall rules are correct

2. **SSL certificates not working**:
   - Check certificate status via Test workflow
   - Verify DNS records are correct

3. **Web servers not responding**:
   - Check instance status via Monitor workflow
   - Verify Nginx configuration

### Workflow Failures

1. **Authentication errors**:
   - Verify `GCP_SA_KEY` secret is correct
   - Check service account permissions

2. **Terraform errors**:
   - Check if resources already exist
   - Verify project ID is correct

3. **Deployment timeouts**:
   - Check instance startup logs
   - Verify network connectivity

## 📊 Performance

- **Deployment Time**: ~30-60 seconds
- **Server Type**: e2-micro (1 vCPU, 1GB RAM) - cost-effective for portfolio projects
- **Load Balancing**: Round-robin with health checks
- **SSL**: Let's Encrypt with automatic renewal

## 🔒 Security Features

- **SSL/TLS Encryption** - All traffic encrypted
- **Firewall Rules** - Restricted access to necessary ports
- **Static IPs** - Fixed IP addresses for stability
- **Health Checks** - Automatic failover for failed servers

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