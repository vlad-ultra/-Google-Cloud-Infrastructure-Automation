#!/bin/bash

# 🚀 Google Cloud Infrastructure Deployment Script
# Main wrapper script that calls the core deployment logic

set -e

echo "🚀 Google Cloud Infrastructure Deployment"
echo "========================================"
echo ""

# Check if we're in the right directory
if [ ! -f "scripts/deployment/deploy.sh" ]; then
    echo "❌ Error: Please run this script from the project root directory"
    echo "   Expected: scripts/deployment/deploy.sh"
    exit 1
fi

# Call the core deployment script
echo "📁 Calling core deployment script..."
echo ""

exec ./scripts/deployment/deploy.sh "$@"
