#!/bin/bash

# 🔐 Export Let's Encrypt Certificates to Google Cloud Storage
# This script exports SSL certificates from all servers to a GCS bucket

set -e

echo "🔐 Exporting Let's Encrypt Certificates to GCS"
echo "============================================="

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

# GCS bucket name
BUCKET_NAME="ssl-certs-${PROJECT_ID}"
echo "🪣 GCS Bucket: $BUCKET_NAME"

# Create GCS bucket if it doesn't exist
echo ""
echo "🪣 Creating GCS bucket for SSL certificates..."
if ! gsutil ls gs://$BUCKET_NAME/ >/dev/null 2>&1; then
    echo "Creating bucket: gs://$BUCKET_NAME"
    gsutil mb gs://$BUCKET_NAME
    echo "✅ Bucket created"
else
    echo "✅ Bucket already exists"
fi

# Set bucket permissions
echo "🔒 Setting bucket permissions..."
gsutil iam ch allUsers:objectViewer gs://$BUCKET_NAME || true

# Check if instances exist
echo ""
echo "🔍 Checking if instances exist..."
if ! gcloud compute instances describe haproxy-prod --zone=europe-west1-b --quiet 2>/dev/null; then
    echo "❌ Error: Instances not found. Run deploy.sh first."
    exit 1
fi

echo "✅ Instances found"

# Get instance details
HAPROXY_INSTANCE="haproxy-prod"
WEB1_INSTANCE="web1-prod"
WEB2_INSTANCE="web2-prod"
ZONE="europe-west1-b"

# Create local directory for certificates
CERT_DIR="ssl-certs-backup"
mkdir -p $CERT_DIR

echo ""
echo "📤 Exporting certificates from servers..."

# Export HAProxy certificates
echo "🔐 Exporting HAProxy certificates..."
if gcloud compute ssh $HAPROXY_INSTANCE --zone=$ZONE --command="sudo ls /etc/haproxy/certs/balancer.svdevops.tech.pem" 2>/dev/null; then
    echo "   📥 Downloading HAProxy certificate..."
    gcloud compute ssh $HAPROXY_INSTANCE --zone=$ZONE --command="sudo cat /etc/haproxy/certs/balancer.svdevops.tech.pem" > $CERT_DIR/haproxy-balancer.svdevops.tech.pem
    echo "   ✅ HAProxy certificate exported"
else
    echo "   ⚠️  HAProxy certificate not found"
fi

# Export Web1 certificates
echo "🔐 Exporting Web1 certificates..."
if gcloud compute ssh $WEB1_INSTANCE --zone=$ZONE --command="sudo ls /etc/letsencrypt/live/web1.svdevops.tech/fullchain.pem" 2>/dev/null; then
    echo "   📥 Downloading Web1 certificate..."
    gcloud compute ssh $WEB1_INSTANCE --zone=$ZONE --command="sudo cat /etc/letsencrypt/live/web1.svdevops.tech/fullchain.pem" > $CERT_DIR/web1.svdevops.tech.pem
    gcloud compute ssh $WEB1_INSTANCE --zone=$ZONE --command="sudo cat /etc/letsencrypt/live/web1.svdevops.tech/privkey.pem" > $CERT_DIR/web1.svdevops.tech.key
    echo "   ✅ Web1 certificate exported"
else
    echo "   ⚠️  Web1 certificate not found"
fi

# Export Web2 certificates
echo "🔐 Exporting Web2 certificates..."
if gcloud compute ssh $WEB2_INSTANCE --zone=$ZONE --command="sudo ls /etc/letsencrypt/live/web2.svdevops.tech/fullchain.pem" 2>/dev/null; then
    echo "   📥 Downloading Web2 certificate..."
    gcloud compute ssh $WEB2_INSTANCE --zone=$ZONE --command="sudo cat /etc/letsencrypt/live/web2.svdevops.tech/fullchain.pem" > $CERT_DIR/web2.svdevops.tech.pem
    gcloud compute ssh $WEB2_INSTANCE --zone=$ZONE --command="sudo cat /etc/letsencrypt/live/web2.svdevops.tech/privkey.pem" > $CERT_DIR/web2.svdevops.tech.key
    echo "   ✅ Web2 certificate exported"
else
    echo "   ⚠️  Web2 certificate not found"
fi

# Upload certificates to GCS
echo ""
echo "☁️ Uploading certificates to GCS..."

# Upload HAProxy certificate
if [ -f "$CERT_DIR/haproxy-balancer.svdevops.tech.pem" ]; then
    echo "   📤 Uploading HAProxy certificate..."
    gsutil cp $CERT_DIR/haproxy-balancer.svdevops.tech.pem gs://$BUCKET_NAME/haproxy/balancer.svdevops.tech.pem
    echo "   ✅ HAProxy certificate uploaded"
fi

# Upload Web1 certificates
if [ -f "$CERT_DIR/web1.svdevops.tech.pem" ]; then
    echo "   📤 Uploading Web1 certificate..."
    gsutil cp $CERT_DIR/web1.svdevops.tech.pem gs://$BUCKET_NAME/web1/web1.svdevops.tech.pem
    gsutil cp $CERT_DIR/web1.svdevops.tech.key gs://$BUCKET_NAME/web1/web1.svdevops.tech.key
    echo "   ✅ Web1 certificate uploaded"
fi

# Upload Web2 certificates
if [ -f "$CERT_DIR/web2.svdevops.tech.pem" ]; then
    echo "   📤 Uploading Web2 certificate..."
    gsutil cp $CERT_DIR/web2.svdevops.tech.pem gs://$BUCKET_NAME/web2/web2.svdevops.tech.pem
    gsutil cp $CERT_DIR/web2.svdevops.tech.key gs://$BUCKET_NAME/web2/web2.svdevops.tech.key
    echo "   ✅ Web2 certificate uploaded"
fi

# Create certificate index
echo ""
echo "📋 Creating certificate index..."
cat > $CERT_DIR/certificate-index.txt << EOF
# SSL Certificates Index
# Generated: $(date)
# Project: $PROJECT_ID
# Bucket: gs://$BUCKET_NAME

## HAProxy Certificates
- balancer.svdevops.tech.pem: gs://$BUCKET_NAME/haproxy/balancer.svdevops.tech.pem

## Web1 Certificates
- web1.svdevops.tech.pem: gs://$BUCKET_NAME/web1/web1.svdevops.tech.pem
- web1.svdevops.tech.key: gs://$BUCKET_NAME/web1/web1.svdevops.tech.key

## Web2 Certificates
- web2.svdevops.tech.pem: gs://$BUCKET_NAME/web2/web2.svdevops.tech.pem
- web2.svdevops.tech.key: gs://$BUCKET_NAME/web2/web2.svdevops.tech.key

## Usage
To download certificates:
gsutil cp gs://$BUCKET_NAME/haproxy/balancer.svdevops.tech.pem ./haproxy-cert.pem
gsutil cp gs://$BUCKET_NAME/web1/web1.svdevops.tech.pem ./web1-cert.pem
gsutil cp gs://$BUCKET_NAME/web2/web2.svdevops.tech.pem ./web2-cert.pem
EOF

# Upload certificate index
gsutil cp $CERT_DIR/certificate-index.txt gs://$BUCKET_NAME/certificate-index.txt

# List uploaded files
echo ""
echo "📋 Certificates in GCS bucket:"
gsutil ls -la gs://$BUCKET_NAME/

# Clean up local files
echo ""
echo "🧹 Cleaning up local files..."
rm -rf $CERT_DIR

echo ""
echo "🎉 Certificates exported to GCS successfully!"
echo "============================================="
echo ""
echo "🪣 GCS Bucket: gs://$BUCKET_NAME"
echo "📋 Index: gs://$BUCKET_NAME/certificate-index.txt"
echo ""
echo "📥 To download certificates:"
echo "   gsutil cp gs://$BUCKET_NAME/haproxy/balancer.svdevops.tech.pem ./haproxy-cert.pem"
echo "   gsutil cp gs://$BUCKET_NAME/web1/web1.svdevops.tech.pem ./web1-cert.pem"
echo "   gsutil cp gs://$BUCKET_NAME/web2/web2.svdevops.tech.pem ./web2-cert.pem"
echo ""
echo "💡 Certificates are now centralized and can be used for new deployments!"
