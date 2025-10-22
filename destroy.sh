#!/bin/bash

# 🗑️ Google Cloud Infrastructure Destruction Script
# Main wrapper script that calls the core destruction logic

set -e

echo "🗑️ Google Cloud Infrastructure Destruction"
echo "=========================================="
echo ""

# Check if we're in the right directory
if [ ! -f "scripts/deployment/destroy-infrastructure.sh" ]; then
    echo "❌ Error: Please run this script from the project root directory"
    echo "   Expected: scripts/deployment/destroy-infrastructure.sh"
    exit 1
fi

# Call the core destruction script
echo "📁 Calling core destruction script..."
echo ""

exec ./scripts/deployment/destroy-infrastructure.sh "$@"
