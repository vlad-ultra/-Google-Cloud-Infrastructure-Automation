# 📁 Project Structure

This document describes the organization and purpose of each file and directory in the Google Cloud Infrastructure Automation project.

## 🏗️ Root Directory

```
📁 Google-Cloud-Infrastructure-Automation/
├── 🚀 deploy.sh                    # Main deployment script (wrapper)
├── 🗑️ destroy.sh                   # Main destruction script (wrapper)
├── 📄 README.md                    # Main project documentation
├── 📄 PROJECT-OVERVIEW.md          # Complete project overview with live URLs
├── 📄 PROJECT-STRUCTURE.md         # This file - project structure documentation
├── 📄 .gitignore                   # Git ignore rules
└── 📁 infrastructure/              # Terraform configurations
```

## 🚀 Main Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| `deploy.sh` | Main deployment wrapper | `./deploy.sh` |
| `destroy.sh` | Main destruction wrapper | `./destroy.sh` |

These are wrapper scripts that call the core logic from `scripts/deployment/`.

## 📁 Infrastructure Directory

```
📁 infrastructure/
├── main.tf                     # Main Terraform configuration
├── variables.tf                # Terraform variables
├── outputs.tf                  # Terraform outputs
├── haproxy.tf                  # HAProxy instance configuration
├── web-servers.tf              # Web servers configuration
├── static-ips.tf               # Static external IP addresses
├── static-internal-ips.tf      # Static internal IP addresses
├── firewall.tf                 # Firewall rules
├── haproxy-config.cfg          # HAProxy configuration template
├── terraform.tfvars            # Terraform variables values
├── terraform.tfvars.example    # Example variables file
└── *.tfstate*                  # Terraform state files (gitignored)
```

## 📁 Scripts Directory

```
📁 scripts/
├── 📁 deployment/              # Core deployment scripts
│   ├── deploy.sh              # Core deployment logic
│   ├── destroy-infrastructure.sh # Core destruction logic
│   └── ultra-fast-deploy.sh   # Fast deployment option
├── 📁 management/              # Infrastructure management
│   ├── apply-configs.sh       # Apply configurations to servers
│   ├── create-new-images.sh   # Create custom images
│   └── restore-configs.sh     # Restore configurations from backups
├── 📁 ssl/                    # SSL certificate management
│   ├── ssl-manager.sh         # Interactive SSL manager
│   ├── ssl.sh                 # SSL wrapper script
│   ├── export-certs-to-gcs.sh # Export certificates to GCS
│   ├── import-certs-from-gcs.sh # Import certificates from GCS
│   └── create-images-with-gcs-certs.sh # Create images with GCS certs
├── 📁 testing/                # Testing scripts
│   └── test-load-balancing.sh # Load balancing tests
├── configure-haproxy.sh       # HAProxy configuration
└── update-content.sh          # Content updates
```

## 📁 Web Apps Directory

```
📁 web-apps/                    # Web server content (auto-synced)
├── web1.html                   # Web Server 1 content
├── web2.html                   # Web Server 2 content
└── haproxy.html                # HAProxy dashboard content
```

**Note**: This directory is automatically synchronized with the web servers during deployment.

## 📁 Configs Directory

```
📁 configs/                     # Configuration backups
└── 📁 current-state/           # Current configuration state
    ├── haproxy.cfg             # HAProxy configuration backup
    ├── web1-nginx.conf         # Web1 Nginx configuration backup
    └── web2-nginx.conf         # Web2 Nginx configuration backup
```

**Note**: This directory contains only configuration files, not content files.

## 📁 GitHub Actions Workflows

```
📁 .github/workflows/
├── 🚀 deploy.yml               # Build and Deploy Infrastructure
├── 🗑️ remove.yml               # Remove GCP Infrastructure
├── 🧪 test-workflow.yml        # Test Infrastructure
├── 📊 monitor.yml              # Monitor Infrastructure
├── 🔄 update-content.yml       # Update Content
├── 🗑️ destroy.yml              # Destroy Infrastructure (alternative)
└── 🐛 debug-auth.yml           # Debug Authentication
```

## 🔧 Script Categories

### 🚀 Deployment Scripts
- **Purpose**: Deploy and destroy infrastructure
- **Location**: `scripts/deployment/`
- **Main Files**: `deploy.sh`, `destroy-infrastructure.sh`

### 🛠️ Management Scripts
- **Purpose**: Manage existing infrastructure
- **Location**: `scripts/management/`
- **Main Files**: `apply-configs.sh`, `create-new-images.sh`

### 🔐 SSL Scripts
- **Purpose**: Manage SSL certificates
- **Location**: `scripts/ssl/`
- **Main Files**: `ssl-manager.sh`, `ssl.sh`

### 🧪 Testing Scripts
- **Purpose**: Test infrastructure functionality
- **Location**: `scripts/testing/`
- **Main Files**: `test-load-balancing.sh`

## 📋 File Naming Conventions

- **Main scripts**: `deploy.sh`, `destroy.sh`
- **Core logic**: Located in `scripts/deployment/`
- **Configuration files**: `.cfg`, `.conf` extensions
- **Terraform files**: `.tf` extension
- **Documentation**: `.md` extension
- **Workflow files**: `.yml` extension

## 🎯 Key Directories to Know

1. **`infrastructure/`** - All Terraform configurations
2. **`scripts/deployment/`** - Core deployment logic
3. **`web-apps/`** - Web content (auto-synced)
4. **`configs/`** - Configuration backups
5. **`.github/workflows/`** - GitHub Actions workflows

## 🔄 Workflow

1. **Deploy**: `./deploy.sh` → calls `scripts/deployment/deploy.sh`
2. **Update Content**: Edit files in `web-apps/` → run `./deploy.sh`
3. **Test**: Use scripts in `scripts/testing/`
4. **Destroy**: `./destroy.sh` → calls `scripts/deployment/destroy-infrastructure.sh`

This structure ensures clean organization, easy maintenance, and clear separation of concerns.
