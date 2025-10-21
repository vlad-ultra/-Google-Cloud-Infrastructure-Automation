#!/bin/bash

# 🔄 Restore SSL Certificates from Google Cloud Storage
# This script restores SSL certificates from GCS

set -e

echo "🔄 Restoring SSL certificates from Google Cloud Storage..."

# Check if we're in the correct directory
if [ ! -f "infrastructure/main.tf" ]; then
    echo "❌ Error: Run script from project root directory"
    exit 1
fi

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
    exit 1
fi

# Get bucket name
BUCKET_NAME="ssl-certificates-${PROJECT_ID}"
echo "🪣 Using GCS bucket: $BUCKET_NAME"

# Check if bucket exists
if ! gsutil ls "gs://$BUCKET_NAME" >/dev/null 2>&1; then
    echo "❌ Error: Bucket gs://$BUCKET_NAME does not exist"
    echo "Run ./save-ssl-to-gcs.sh first"
    exit 1
fi

# Download certificates from GCS
echo "⬇️ Downloading certificates from Google Cloud Storage..."
gsutil -m cp -r "gs://$BUCKET_NAME/letsencrypt/*" ./ssl-restore/

# Upload to HAProxy
echo "⬆️ Uploading certificates to HAProxy..."
gcloud compute scp --recurse ./ssl-restore/letsencrypt haproxy-prod:/tmp/ssl-restore/

# Restore certificates on HAProxy
echo "🔧 Restoring certificates on HAProxy..."
gcloud compute ssh haproxy-prod --zone=europe-west1-b --command="
# Stop HAProxy
sudo systemctl stop haproxy

# Restore certificates
sudo cp -r /tmp/ssl-restore/letsencrypt/* /etc/letsencrypt/

# Create combined certificate for HAProxy
sudo mkdir -p /etc/haproxy/certs
sudo bash -c 'cat /etc/letsencrypt/live/balancer.svdevops.tech/fullchain.pem /etc/letsencrypt/live/balancer.svdevops.tech/privkey.pem > /etc/haproxy/certs/svdevops.tech.pem'

# Start HAProxy
sudo systemctl start haproxy

# Cleanup
rm -rf /tmp/ssl-restore

echo 'SSL certificates restored successfully!'
"

# Cleanup local files
rm -rf ./ssl-restore

echo "✅ SSL certificates restored from Google Cloud Storage!"
echo "======================================================"
echo ""
echo "🌐 Your HTTPS sites should be working:"
echo "https://balancer.svdevops.tech"
echo "https://stats.svdevops.tech"
echo ""
echo "✅ SSL certificates restoration completed!"
