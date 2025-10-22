#!/bin/bash

# 🔐 Import Let's Encrypt Certificates from Google Cloud Storage
# This script imports SSL certificates from GCS bucket to servers

set -e

echo "🔐 Importing Let's Encrypt Certificates from GCS"
echo "==============================================="

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

# Check if bucket exists
echo ""
echo "🔍 Checking if GCS bucket exists..."
if ! gsutil ls gs://$BUCKET_NAME/ >/dev/null 2>&1; then
    echo "❌ Error: GCS bucket not found: gs://$BUCKET_NAME"
    echo "Run export-certs-to-gcs.sh first to create the bucket and export certificates"
    exit 1
fi

echo "✅ GCS bucket found"

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
CERT_DIR="ssl-certs-import"
mkdir -p $CERT_DIR

echo ""
echo "📥 Downloading certificates from GCS..."

# Download HAProxy certificate
echo "🔐 Downloading HAProxy certificate..."
if gsutil ls gs://$BUCKET_NAME/haproxy/balancer.svdevops.tech.pem >/dev/null 2>&1; then
    gsutil cp gs://$BUCKET_NAME/haproxy/balancer.svdevops.tech.pem $CERT_DIR/haproxy-balancer.svdevops.tech.pem
    echo "   ✅ HAProxy certificate downloaded"
else
    echo "   ⚠️  HAProxy certificate not found in GCS"
fi

# Download Web1 certificates
echo "🔐 Downloading Web1 certificates..."
if gsutil ls gs://$BUCKET_NAME/web1/web1.svdevops.tech.pem >/dev/null 2>&1; then
    gsutil cp gs://$BUCKET_NAME/web1/web1.svdevops.tech.pem $CERT_DIR/web1.svdevops.tech.pem
    gsutil cp gs://$BUCKET_NAME/web1/web1.svdevops.tech.key $CERT_DIR/web1.svdevops.tech.key
    echo "   ✅ Web1 certificates downloaded"
else
    echo "   ⚠️  Web1 certificates not found in GCS"
fi

# Download Web2 certificates
echo "🔐 Downloading Web2 certificates..."
if gsutil ls gs://$BUCKET_NAME/web2/web2.svdevops.tech.pem >/dev/null 2>&1; then
    gsutil cp gs://$BUCKET_NAME/web2/web2.svdevops.tech.pem $CERT_DIR/web2.svdevops.tech.pem
    gsutil cp gs://$BUCKET_NAME/web2/web2.svdevops.tech.key $CERT_DIR/web2.svdevops.tech.key
    echo "   ✅ Web2 certificates downloaded"
else
    echo "   ⚠️  Web2 certificates not found in GCS"
fi

echo ""
echo "📤 Uploading certificates to servers..."

# Upload HAProxy certificate
if [ -f "$CERT_DIR/haproxy-balancer.svdevops.tech.pem" ]; then
    echo "🔐 Uploading HAProxy certificate..."
    gcloud compute scp $CERT_DIR/haproxy-balancer.svdevops.tech.pem $HAPROXY_INSTANCE:/tmp/balancer.svdevops.tech.pem --zone=$ZONE
    gcloud compute ssh $HAPROXY_INSTANCE --zone=$ZONE --command="
        sudo mkdir -p /etc/haproxy/certs
        sudo cp /tmp/balancer.svdevops.tech.pem /etc/haproxy/certs/
        sudo chown haproxy:haproxy /etc/haproxy/certs/balancer.svdevops.tech.pem
        sudo chmod 644 /etc/haproxy/certs/balancer.svdevops.tech.pem
        sudo systemctl restart haproxy
        rm -f /tmp/balancer.svdevops.tech.pem
    "
    echo "   ✅ HAProxy certificate uploaded and applied"
fi

# Upload Web1 certificates
if [ -f "$CERT_DIR/web1.svdevops.tech.pem" ]; then
    echo "🔐 Uploading Web1 certificates..."
    gcloud compute scp $CERT_DIR/web1.svdevops.tech.pem $WEB1_INSTANCE:/tmp/web1.svdevops.tech.pem --zone=$ZONE
    gcloud compute scp $CERT_DIR/web1.svdevops.tech.key $WEB1_INSTANCE:/tmp/web1.svdevops.tech.key --zone=$ZONE
    gcloud compute ssh $WEB1_INSTANCE --zone=$ZONE --command="
        sudo mkdir -p /etc/letsencrypt/live/web1.svdevops.tech
        sudo cp /tmp/web1.svdevops.tech.pem /etc/letsencrypt/live/web1.svdevops.tech/fullchain.pem
        sudo cp /tmp/web1.svdevops.tech.key /etc/letsencrypt/live/web1.svdevops.tech/privkey.pem
        sudo chown -R root:root /etc/letsencrypt/live/web1.svdevops.tech/
        sudo chmod 644 /etc/letsencrypt/live/web1.svdevops.tech/fullchain.pem
        sudo chmod 600 /etc/letsencrypt/live/web1.svdevops.tech/privkey.pem
        sudo systemctl reload nginx
        rm -f /tmp/web1.svdevops.tech.pem /tmp/web1.svdevops.tech.key
    "
    echo "   ✅ Web1 certificates uploaded and applied"
fi

# Upload Web2 certificates
if [ -f "$CERT_DIR/web2.svdevops.tech.pem" ]; then
    echo "🔐 Uploading Web2 certificates..."
    gcloud compute scp $CERT_DIR/web2.svdevops.tech.pem $WEB2_INSTANCE:/tmp/web2.svdevops.tech.pem --zone=$ZONE
    gcloud compute scp $CERT_DIR/web2.svdevops.tech.key $WEB2_INSTANCE:/tmp/web2.svdevops.tech.key --zone=$ZONE
    gcloud compute ssh $WEB2_INSTANCE --zone=$ZONE --command="
        sudo mkdir -p /etc/letsencrypt/live/web2.svdevops.tech
        sudo cp /tmp/web2.svdevops.tech.pem /etc/letsencrypt/live/web2.svdevops.tech/fullchain.pem
        sudo cp /tmp/web2.svdevops.tech.key /etc/letsencrypt/live/web2.svdevops.tech/privkey.pem
        sudo chown -R root:root /etc/letsencrypt/live/web2.svdevops.tech/
        sudo chmod 644 /etc/letsencrypt/live/web2.svdevops.tech/fullchain.pem
        sudo chmod 600 /etc/letsencrypt/live/web2.svdevops.tech/privkey.pem
        sudo systemctl reload nginx
        rm -f /tmp/web2.svdevops.tech.pem /tmp/web2.svdevops.tech.key
    "
    echo "   ✅ Web2 certificates uploaded and applied"
fi

# Test certificates
echo ""
echo "🧪 Testing certificates..."

# Test HAProxy
echo "📡 Testing HAProxy HTTPS..."
HAPROXY_IP=$(cd infrastructure && terraform output -raw haproxy_external_ip)
HTTPS_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" https://balancer.svdevops.tech -k || echo "000")
if [ "$HTTPS_RESPONSE" = "200" ]; then
    echo "   ✅ HAProxy HTTPS working (200)"
else
    echo "   ❌ HAProxy HTTPS failed ($HTTPS_RESPONSE)"
fi

# Test Web1
echo "📡 Testing Web1 HTTPS..."
WEB1_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" https://web1.svdevops.tech -k || echo "000")
if [ "$WEB1_RESPONSE" = "200" ]; then
    echo "   ✅ Web1 HTTPS working (200)"
else
    echo "   ❌ Web1 HTTPS failed ($WEB1_RESPONSE)"
fi

# Test Web2
echo "📡 Testing Web2 HTTPS..."
WEB2_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" https://web2.svdevops.tech -k || echo "000")
if [ "$WEB2_RESPONSE" = "200" ]; then
    echo "   ✅ Web2 HTTPS working (200)"
else
    echo "   ❌ Web2 HTTPS failed ($WEB2_RESPONSE)"
fi

# Clean up local files
echo ""
echo "🧹 Cleaning up local files..."
rm -rf $CERT_DIR

echo ""
echo "🎉 Certificates imported from GCS successfully!"
echo "=============================================="
echo ""
echo "🌐 URLs:"
echo "   Load Balancer: https://balancer.svdevops.tech"
echo "   Web1: https://web1.svdevops.tech"
echo "   Web2: https://web2.svdevops.tech"
echo ""
echo "💡 Certificates are now restored from GCS bucket!"
