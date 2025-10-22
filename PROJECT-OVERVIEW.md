# 🚀 Google Cloud Infrastructure Automation

> **Professional DevOps automation solution for deploying highly available web infrastructure on Google Cloud Platform**

[![GitHub Actions](https://img.shields.io/badge/GitHub%20Actions-Ready-brightgreen)](https://github.com/vlad-ultra/-Google-Cloud-Infrastructure-Automation/actions)
[![Terraform](https://img.shields.io/badge/Terraform-Infrastructure%20as%20Code-blue)](https://terraform.io)
[![Google Cloud](https://img.shields.io/badge/Google%20Cloud-Platform-orange)](https://cloud.google.com)
[![HAProxy](https://img.shields.io/badge/HAProxy-Load%20Balancer-red)](https://haproxy.org)
[![Nginx](https://img.shields.io/badge/Nginx-Web%20Server-green)](https://nginx.org)

## ✨ Key Features

- **⚡ Ultra-Fast Deployment** - Deploy infrastructure in ~30-60 seconds
- **💰 Cost-Effective** - Uses e2-micro instances (1 vCPU, 1GB RAM)
- **🔄 Automatic Content Sync** - Auto-applies HTML content from `web-apps/`
- **🔐 SSL Management** - Let's Encrypt certificates with auto-renewal
- **⚖️ Load Balancing** - HAProxy with health checks and SSL termination
- **🚀 GitHub Actions CI/CD** - Automated deployment and testing
- **📊 Monitoring** - Built-in health checks and load balancing tests

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

## 🌐 Live Demo

| Service | URL | Description |
|---------|-----|-------------|
| **Load Balancer** | https://balancer.svdevops.tech | Main entry point with load balancing |
| **Web Server 1** | https://web1.svdevops.tech | Direct access to Web Server 1 |
| **Web Server 2** | https://web2.svdevops.tech | Direct access to Web Server 2 |
| **HAProxy Stats** | https://balancer.svdevops.tech/stats | Load balancer statistics |

## 🚀 Quick Start

### Option 1: GitHub Actions (Recommended)

1. **Fork this repository**
2. **Set up GitHub Secrets**:
   - `GCP_SA_KEY` - Your Google Cloud Service Account JSON key
   - `GCP_PROJECT_ID` - Your GCP project ID
3. **Deploy Infrastructure**:
   - Go to Actions → "🚀 Build and Deploy Infrastructure"
   - Click "Run workflow" → Select `prod` → Type `YES` → Run
4. **Test your deployment**:
   - Visit https://balancer.svdevops.tech
   - Check load balancing with testing commands

### Option 2: Local Deployment

```bash
# Clone the repository
git clone https://github.com/vlad-ultra/-Google-Cloud-Infrastructure-Automation.git
cd Google-Cloud-Infrastructure-Automation

# Configure Google Cloud
gcloud auth login
gcloud config set project YOUR_PROJECT_ID

# Deploy infrastructure
./deploy.sh
```

## 🧪 Testing

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

## 📋 Available Workflows

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| **🚀 Build and Deploy Infrastructure** | Manual | Deploy/update infrastructure with content sync |
| **🗑️ Remove GCP Infrastructure** | Manual | Destroy infrastructure (preserves static IPs) |
| **🧪 Test Infrastructure** | Manual | Comprehensive infrastructure testing |
| **📊 Monitor Infrastructure** | Manual | Health checks and monitoring |
| **🔄 Update Content** | Manual | Update web content without redeployment |

## 🛠️ Tech Stack

- **Infrastructure**: Google Cloud Platform (GCP)
- **IaC**: Terraform
- **Load Balancer**: HAProxy
- **Web Servers**: Nginx
- **SSL**: Let's Encrypt
- **CI/CD**: GitHub Actions
- **Monitoring**: Custom health checks

## 📁 Project Structure

```
📁 Google-Cloud-Infrastructure-Automation/
├── 🚀 deploy.sh                    # Main deployment script
├── 🗑️ destroy.sh                   # Main destruction script
├── 📁 infrastructure/              # Terraform configurations
├── 📁 scripts/                     # Organized utility scripts
│   ├── deployment/                 # Deployment scripts
│   ├── management/                 # Management scripts
│   ├── ssl/                       # SSL certificate management
│   └── testing/                   # Testing scripts
├── 📁 web-apps/                    # Web server content (auto-synced)
├── 📁 configs/                     # Configuration backups
└── 📁 .github/workflows/           # GitHub Actions workflows
```

## 💡 Perfect For

- **Portfolio Projects** - Showcase DevOps skills
- **Learning** - Understand cloud infrastructure
- **Prototyping** - Quick infrastructure deployment
- **CI/CD Demos** - Automated deployment examples
- **Load Balancing** - High availability demonstrations

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**Vlad Stadnyk** - DevOps Engineer
- GitHub: [@vlad-ultra](https://github.com/vlad-ultra)
- Project: Google Cloud Infrastructure Automation

---

**🎯 Ready for Production** - This infrastructure is production-ready and can handle real-world traffic with high availability and performance.
