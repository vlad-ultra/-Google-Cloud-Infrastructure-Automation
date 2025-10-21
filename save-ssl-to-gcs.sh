#!/bin/bash

# 💾 Save SSL Certificates to Google Cloud Storage
# This script saves SSL certificates to GCS for backup and reuse

set -e

echo "💾 Saving SSL certificates to Google Cloud Storage..."

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

# Create GCS bucket for certificates
BUCKET_NAME="ssl-certificates-${PROJECT_ID}"
echo "🪣 Creating GCS bucket: $BUCKET_NAME"

# Create bucket if it doesn't exist
gsutil mb -p "$PROJECT_ID" -c STANDARD -l europe-west1 "gs://$BUCKET_NAME" 2>/dev/null || echo "Bucket already exists"

# Download certificates from HAProxy
echo "📥 Downloading certificates from HAProxy..."

# Check if certificates exist on HAProxy
if ! gcloud compute ssh haproxy-prod --zone=europe-west1-b --command="sudo test -d /etc/letsencrypt/live/balancer.svdevops.tech" 2>/dev/null; then
    echo "❌ Error: SSL certificates not found on HAProxy"
    echo "Run deploy.sh first to generate certificates"
    exit 1
fi

gcloud compute ssh haproxy-prod --zone=europe-west1-b --command="
# Create backup directory
sudo mkdir -p /tmp/ssl-backup
sudo cp -r /etc/letsencrypt /tmp/ssl-backup/
# Fix ownership for current user
sudo chown -R \$(whoami):\$(whoami) /tmp/ssl-backup
"

# Download to local machine
echo "⬇️ Downloading certificates to local machine..."
if ! gcloud compute scp --recurse haproxy-prod:/tmp/ssl-backup/letsencrypt ./ssl-backup/ --zone=europe-west1-b; then
    echo "❌ Error: Failed to download certificates from HAProxy"
    exit 1
fi

# Upload to GCS
echo "⬆️ Uploading certificates to Google Cloud Storage..."
if ! gsutil -m cp -r ./ssl-backup/* "gs://$BUCKET_NAME/letsencrypt/"; then
    echo "❌ Error: Failed to upload certificates to GCS"
    exit 1
fi

# Create metadata file
echo "📝 Creating metadata file..."
cat > ssl-metadata.json << EOF
{
  "project_id": "$PROJECT_ID",
  "bucket_name": "$BUCKET_NAME",
  "domains": ["balancer.svdevops.tech", "stats.svdevops.tech"],
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "expires_at": "$(date -d '+90 days' -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

gsutil cp ssl-metadata.json "gs://$BUCKET_NAME/"

# Cleanup
rm -rf ./ssl-backup ssl-metadata.json

echo "✅ SSL certificates saved to Google Cloud Storage!"
echo "=================================================="
echo ""
echo "📦 Bucket: gs://$BUCKET_NAME"
echo "📁 Path: gs://$BUCKET_NAME/letsencrypt/"
echo "📄 Metadata: gs://$BUCKET_NAME/ssl-metadata.json"
echo ""
echo "🔧 To restore certificates:"
echo "   ./restore-ssl-from-gcs.sh"
echo ""
echo "✅ SSL certificates backup completed!"
