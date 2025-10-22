#!/bin/bash

# 🖼️ Create New Images with Correct Configuration
# This script creates new images with the correct HAProxy and Nginx configurations

set -e

echo "🖼️ Creating New Images with Correct Configuration"
echo "================================================"

# Navigate to project directory
cd "$(dirname "$0")"

# Check if we're in the correct directory
if [ ! -f "infrastructure/main.tf" ]; then
    echo "❌ Error: Run script from project root directory"
    exit 1
fi

echo "📁 Working directory: $(pwd)"

# Check Google Cloud authentication
echo "🔐 Checking Google Cloud authentication..."
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo "❌ Error: Not authenticated to Google Cloud"
    echo "Run: gcloud auth login"
    exit 1
fi

# Get project ID
PROJECT_ID=$(gcloud config get-value project)
if [ -z "$PROJECT_ID" ]; then
    echo "❌ Error: PROJECT_ID not set"
    echo "Run: gcloud config set project YOUR_PROJECT_ID"
    exit 1
fi

echo "✅ Project ID: $PROJECT_ID"

# Check if instances exist
echo "🔍 Checking if instances exist..."
if ! gcloud compute instances describe haproxy-prod --zone=europe-west1-b --quiet 2>/dev/null; then
    echo "❌ Error: Instances not found. Run deploy.sh first."
    exit 1
fi

echo "✅ Instances found"

# Apply correct configurations first
echo ""
echo "🔧 Applying correct configurations to running instances..."

# Apply HAProxy configuration
echo "📤 Applying HAProxy configuration..."
./scripts/configure-haproxy.sh

# Update content on web servers
echo "📝 Updating content on web servers..."
./update-content.sh

# Wait for configurations to be applied
echo "⏳ Waiting for configurations to be applied..."
sleep 10

# Create new images
echo ""
echo "🖼️ Creating new images..."

# Stop instances
echo "🛑 Stopping instances..."
gcloud compute instances stop haproxy-prod web1-prod web2-prod --zone=europe-west1-b --quiet

# Wait for instances to stop
echo "⏳ Waiting for instances to stop..."
sleep 30

# Create HAProxy image
echo "📸 Creating HAProxy image..."
gcloud compute images create haproxy-prod-image-v3 \
    --source-disk=haproxy-prod \
    --source-disk-zone=europe-west1-b \
    --family=haproxy-prod \
    --description="HAProxy with correct configuration and Let's Encrypt certificates"

# Create Web1 image
echo "📸 Creating Web1 image..."
gcloud compute images create web1-prod-image-v3 \
    --source-disk=web1-prod \
    --source-disk-zone=europe-west1-b \
    --family=web1-prod \
    --description="Web1 with correct Nginx configuration"

# Create Web2 image
echo "📸 Creating Web2 image..."
gcloud compute images create web2-prod-image-v3 \
    --source-disk=web2-prod \
    --source-disk-zone=europe-west1-b \
    --family=web2-prod \
    --description="Web2 with correct Nginx configuration"

# Start instances
echo "🚀 Starting instances..."
gcloud compute instances start haproxy-prod web1-prod web2-prod --zone=europe-west1-b --quiet

echo ""
echo "🎉 New images created successfully!"
echo "=================================="
echo ""
echo "📸 New images:"
echo "   - haproxy-prod-image-v3"
echo "   - web1-prod-image-v3"
echo "   - web2-prod-image-v3"
echo ""
echo "🔧 Next steps:"
echo "   1. Update Terraform to use new images"
echo "   2. Test deployment with new images"
echo "   3. Verify configurations are preserved"
