# 🚀 GitHub Actions Workflows

This directory contains GitHub Actions workflows for automated deployment, monitoring, and content management of the DevOps infrastructure.

## 📋 Available Workflows

### 1. 🚀 Auto Deploy Infrastructure (`deploy.yml`)

**Trigger:** Push to `main` branch
**Purpose:** Deploy complete infrastructure with new architecture

**Features:**
- ✅ Deploy infrastructure using Terraform
- ✅ Configure SSL certificates on each web server
- ✅ Setup HAProxy with HTTPS roundrobin
- ✅ Test all domains (HTTPS)
- ✅ Test roundrobin functionality
- ✅ Test stop/start functionality
- ✅ Generate deployment summary

**Jobs:**
- `deploy`: Main deployment job
- `test-stop-start`: Test cost management functionality
- `destroy`: Cleanup on PR close

### 2. 🔄 Update Content (`update-content.yml`)

**Trigger:** Changes to `web-apps/**` files
**Purpose:** Update HTML content on web servers

**Features:**
- ✅ Automatically detect content changes
- ✅ Update content on all web servers
- ✅ Test all domains after update
- ✅ Verify roundrobin with new content

### 3. 📊 Monitor Infrastructure (`monitor.yml`)

**Trigger:** Every 15 minutes + manual
**Purpose:** Health monitoring and alerting

**Features:**
- ✅ Check instance status
- ✅ Test all domains
- ✅ Generate health reports
- ✅ Alert on failures
- ✅ Provide troubleshooting steps

## 🔧 Workflow Configuration

### Required Secrets

Set these secrets in your GitHub repository:

```bash
GCP_PROJECT_ID=your-project-id
GCP_SA_KEY=your-service-account-key-json
```

### Service Account Permissions

Your service account needs these roles:
- `Compute Instance Admin`
- `Storage Admin`
- `DNS Administrator`
- `Service Account User`

## 📊 Workflow Status

| Workflow | Status | Description |
|----------|--------|-------------|
| `deploy` | ✅ Active | Deploys infrastructure on push to main |
| `update-content` | ✅ Active | Updates content on web-apps changes |
| `monitor` | ✅ Active | Monitors health every 15 minutes |

## 🎯 Workflow Features

### Deployment Workflow
- **Infrastructure as Code**: Full Terraform automation
- **SSL/TLS**: Automatic certificate generation
- **High Availability**: HAProxy with roundrobin
- **Testing**: Comprehensive domain testing
- **Cost Management**: Stop/start functionality testing

### Content Update Workflow
- **Automatic Detection**: Triggers on web-apps changes
- **Multi-Server Update**: Updates all web servers
- **Verification**: Tests all domains after update
- **Roundrobin Testing**: Verifies load balancing

### Monitoring Workflow
- **Health Checks**: Instance and domain monitoring
- **Alerting**: Automatic failure detection
- **Reporting**: Detailed health reports
- **Troubleshooting**: Built-in diagnostic steps

## 🚨 Troubleshooting

### Common Issues

1. **Deployment Fails**
   - Check GCP credentials
   - Verify project permissions
   - Check Terraform state

2. **Content Update Fails**
   - Verify instances are running
   - Check SSH connectivity
   - Verify file permissions

3. **Monitoring Alerts**
   - Check instance status
   - Verify domain DNS
   - Check SSL certificates

### Manual Actions

```bash
# Deploy infrastructure
./deploy.sh

# Update content
./update-content.sh

# Stop instances
./stop-instances.sh

# Start instances
./start-instances.sh

# Check health
curl https://balancer.svdevops.tech
```

## 📈 Monitoring Dashboard

The monitoring workflow provides:
- Instance status monitoring
- Domain health checks
- SSL certificate status
- Roundrobin functionality
- Cost management verification

## 🔄 Workflow Triggers

| Event | Workflow | Action |
|-------|----------|--------|
| Push to main | deploy.yml | Deploy infrastructure |
| Changes to web-apps/ | update-content.yml | Update content |
| Every 15 minutes | monitor.yml | Health check |
| PR closed | deploy.yml | Destroy infrastructure |
| Manual trigger | All workflows | Run on demand |

## 💡 Best Practices

1. **Always test locally** before pushing
2. **Monitor workflow logs** for issues
3. **Use manual triggers** for testing
4. **Check health reports** regularly
5. **Keep secrets secure** and rotated

## 🎉 Success Criteria

A successful deployment should show:
- ✅ All instances running
- ✅ All domains accessible via HTTPS
- ✅ Roundrobin working correctly
- ✅ SSL certificates valid
- ✅ Stop/start functionality working
- ✅ Content updates working
