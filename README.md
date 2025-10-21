# 🚀 DevOps Master System v.3.0

A production-ready, highly available web application infrastructure on Google Cloud Platform (GCP) with advanced DevOps practices, automated CI/CD, and cost optimization.

## ⚡ Features

- **🚀 Fast Deployment**: ~30 seconds using pre-built images
- **🔒 SSL/TLS Security**: Individual certificates for each web server
- **⚖️ Load Balancing**: HAProxy with HTTPS roundrobin
- **🌐 High Availability**: Multiple web servers with health checks
- **💰 Cost Optimization**: Stop/start scripts for cost management
- **🔄 CI/CD Automation**: GitHub Actions for deployment and monitoring
- **📊 Monitoring**: Automated health checks and alerting
- **🏗️ Infrastructure as Code**: Complete Terraform automation
- **🔐 Security**: Let's Encrypt SSL with automatic renewal
- **📦 Backup**: SSL certificates stored in Google Cloud Storage

## 🏗️ Architecture

```
Internet → HAProxy (Load Balancer) → Web Server 1 (HTTPS)
                                → Web Server 2 (HTTPS)
```

**Components:**
- **HAProxy**: Load balancer with HTTPS roundrobin and statistics
- **Web Server 1 & 2**: Nginx servers with individual SSL certificates
- **Static IPs**: Fixed internal and external IPs for stability
- **SSL/TLS**: Let's Encrypt certificates with automatic renewal
- **Monitoring**: Automated health checks and alerting
- **CI/CD**: GitHub Actions for deployment and content updates

## 🚀 Quick Start

1. **Deploy infrastructure:**
   ```bash
   ./deploy.sh
   ```

2. **Update content:**
   ```bash
   ./update-content.sh
   ```

3. **Stop instances (save money):**
   ```bash
   ./stop-instances.sh
   ```

4. **Start instances:**
   ```bash
   ./start-instances.sh
   ```

5. **Destroy infrastructure:**
   ```bash
   ./destroy-infrastructure.sh
   ```

## 🌐 Access

After deployment:
- **Load Balancer**: https://balancer.svdevops.tech
- **HAProxy Stats**: https://stats.svdevops.tech
- **Web Server 1**: https://web1.svdevops.tech
- **Web Server 2**: https://web2.svdevops.tech

## 📁 Project Structure

```
├── deploy.sh                    # Main deployment script
├── update-content.sh            # Update HTML content
├── stop-instances.sh            # Stop instances (save money)
├── start-instances.sh           # Start instances with HTTPS
├── destroy-infrastructure.sh    # Destroy all infrastructure
├── configure-haproxy.sh         # HAProxy configuration script
├── save-ssl-to-gcs.sh          # Save SSL certificates to GCS
├── restore-ssl-from-gcs.sh     # Restore SSL certificates from GCS
├── infrastructure/              # Terraform configuration
│   ├── main.tf
│   ├── haproxy.tf
│   ├── web-servers.tf
│   ├── static-ips.tf
│   ├── static-internal-ips.tf
│   └── firewall.tf
└── web-apps/                    # HTML content
    ├── web1.html
    ├── web2.html
    └── haproxy.html
```

## 🔧 Configuration

### Fixed Internal IPs

The project uses **fixed internal IPs** to prevent configuration issues:

- **Web Server 1**: `10.132.15.215`
- **Web Server 2**: `10.132.15.216`
- **HAProxy**: `10.132.15.214`

### SSL Certificates

- **Automatic generation** with Let's Encrypt
- **Backup to GCS** for fast restoration
- **Auto-renewal** via cron job
- **HTTPS redirect** for all domains

### Pre-built Images

- **haproxy-loadbalancer-image**: HAProxy with basic configuration
- **web-server-1-image**: Nginx with custom content
- **web-server-2-image**: Nginx with custom content

## 💰 Cost Optimization

Use `stop-instances.sh` to stop all instances and save money:
- **Instances**: STOPPED (no compute charges)
- **Static IPs**: PRESERVED (minimal cost ~$0.01/hour)
- **Disks**: PRESERVED (minimal cost ~$0.04/GB/month)

## 🔑 SSH Access

```bash
# HAProxy
gcloud compute ssh haproxy-prod --zone=europe-west1-b --tunnel-through-iap

# Web Server 1
gcloud compute ssh web1-prod --zone=europe-west1-b --tunnel-through-iap

# Web Server 2
gcloud compute ssh web2-prod --zone=europe-west1-b --tunnel-through-iap
```

## 📊 Monitoring

- **HAProxy Stats**: https://stats.svdevops.tech
- **Health Checks**: Automatic monitoring of web servers
- **Load Balancing**: Round-robin distribution
- **SSL Certificate Status**: Automatic monitoring and renewal

## 🛠️ Troubleshooting

### Common Issues

1. **IP Address Changes**: Use fixed internal IPs (already configured)
2. **Service Not Starting**: Check systemd status
3. **Load Balancer Issues**: Check HAProxy configuration
4. **SSL Issues**: Check certificate status and renewal

### Logs

```bash
# HAProxy logs
sudo journalctl -u haproxy.service -f

# Nginx logs
sudo journalctl -u nginx.service -f

# SSL renewal logs
sudo journalctl -u certbot.timer -f
```

## 🔄 GitHub Actions CI/CD

The project includes automated CI/CD workflows:

### 🚀 Deploy Workflow
- **Trigger**: Push to `main` branch
- **Actions**: Deploy infrastructure, configure SSL, test domains
- **Features**: Full deployment with testing and stop/start verification

### 🔄 Update Content Workflow
- **Trigger**: Changes to `web-apps/**` files
- **Actions**: Update HTML content on all web servers
- **Features**: Automatic content deployment and verification

### 📊 Monitor Workflow
- **Trigger**: Every 15 minutes + manual
- **Actions**: Health checks, domain testing, alerting
- **Features**: Continuous monitoring and failure detection

## 📝 Notes

- **Fixed Internal IPs**: Prevents configuration issues between deployments
- **Pre-built Images**: Faster deployment (~30 seconds)
- **HTTPS Support**: All domains work with SSL certificates
- **Cost Optimization**: Stop instances when not in use
- **SSL Backup**: Certificates saved to Google Cloud Storage
- **Auto-renewal**: SSL certificates renew automatically
- **CI/CD Automation**: GitHub Actions for deployment and monitoring
- **Individual SSL**: Each web server has its own SSL certificate
- **HTTPS Roundrobin**: Load balancing with SSL termination