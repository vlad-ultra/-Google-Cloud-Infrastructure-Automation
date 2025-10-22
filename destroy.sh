#!/bin/bash

# 🗑️ Infrastructure Destruction Script Wrapper
# This script provides easy access to infrastructure destruction

set -e

echo "🗑️ Google Cloud Infrastructure Destruction"
echo "=========================================="

# Navigate to project directory
cd "$(dirname "$0")"

# Check if we're in the correct directory
if [ ! -f "infrastructure/main.tf" ]; then
    echo "❌ Error: Run script from project root directory"
    exit 1
fi

echo " Working directory: $(pwd)"
echo ""

# Run the actual destruction script
echo "🗑️ Starting infrastructure destruction..."
exec ./scripts/deployment/destroy-infrastructure.sh
