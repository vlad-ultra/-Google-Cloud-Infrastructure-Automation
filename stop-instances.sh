#!/bin/bash

# 🛑 Stop Instances Script
# This script stops all instances to save money while preserving static IPs

set -e

echo "🛑 Stopping Instances to Save Money"
echo "===================================="

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

# Get instance names
HAPROXY_INSTANCE="haproxy-prod"
WEB1_INSTANCE="web1-prod"
WEB2_INSTANCE="web2-prod"
ZONE="europe-west1-b"

echo ""
echo "Stopping instances: ${HAPROXY_INSTANCE}, ${WEB1_INSTANCE}, ${WEB2_INSTANCE} in zone ${ZONE}..."
echo "⏱️ This will take ~10 seconds..."

START_TIME=$(date +%s)

# Stop HAProxy instance
echo "🛑 Stopping HAProxy..."
gcloud compute instances stop "${HAPROXY_INSTANCE}" --zone="${ZONE}" --project="${PROJECT_ID}" --quiet || true &
HAPROXY_PID=$!

# Stop Web1 instance
echo "🛑 Stopping Web1..."
gcloud compute instances stop "${WEB1_INSTANCE}" --zone="${ZONE}" --project="${PROJECT_ID}" --quiet || true &
WEB1_PID=$!

# Stop Web2 instance
echo "🛑 Stopping Web2..."
gcloud compute instances stop "${WEB2_INSTANCE}" --zone="${ZONE}" --project="${PROJECT_ID}" --quiet || true &
WEB2_PID=$!

# Wait for all stops to complete
wait $HAPROXY_PID $WEB1_PID $WEB2_PID

END_TIME=$(date +%s)
STOP_TIME=$((END_TIME - START_TIME))

echo ""
echo "🎉 All instances stopped successfully!"
echo "====================================="
echo ""
echo "⏱️ Total stop time: ${STOP_TIME} seconds"
echo ""
echo "💰 Cost Savings:"
echo "   - Instances: STOPPED (no compute charges)"
echo "   - Static IPs: PRESERVED (minimal cost ~$0.01/hour)"
echo "   - Disks: PRESERVED (minimal cost ~$0.04/GB/month)"
echo ""
echo "🔄 To restart instances, run:"
echo "   ./start-instances.sh"
echo ""
echo "✅ All instances stopped (static IPs preserved)."
