#!/bin/bash

# 🔐 SSL Management Quick Access
# This script provides quick access to SSL management tools

set -e

echo "🔐 SSL Management Quick Access"
echo "============================="

# Navigate to project directory
cd "$(dirname "$0")"

# Check if ssl-management directory exists
if [ ! -d "ssl-management" ]; then
    echo "❌ Error: ssl-management directory not found"
    exit 1
fi

# Navigate to ssl-management directory
cd ssl-management

# Check if ssl-manager.sh exists
if [ ! -f "ssl-manager.sh" ]; then
    echo "❌ Error: ssl-manager.sh not found in ssl-management directory"
    exit 1
fi

# Run SSL manager
echo "🚀 Starting SSL Manager..."
./ssl-manager.sh
