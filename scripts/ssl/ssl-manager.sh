#!/bin/bash

# 🔐 SSL Certificate Manager
# This script provides a menu-driven interface for managing SSL certificates

set -e

echo "🔐 SSL Certificate Manager"
echo "========================="

# Navigate to project directory
cd "$(dirname "$0")"

# Check if we're in the correct directory
if [ ! -f "infrastructure/main.tf" ]; then
    echo "❌ Error: Run script from project root directory"
    exit 1
fi

# Get project ID
PROJECT_ID=$(gcloud config get-value project)
BUCKET_NAME="ssl-certs-${PROJECT_ID}"

# Function to show menu
show_menu() {
    echo ""
    echo "📋 SSL Certificate Management Options:"
    echo "====================================="
    echo "1. Export certificates to GCS bucket"
    echo "2. Import certificates from GCS bucket"
    echo "3. Create new images with GCS certificates"
    echo "4. List certificates in GCS bucket"
    echo "5. Download certificates locally"
    echo "6. Test certificate validity"
    echo "7. Show certificate information"
    echo "8. Exit"
    echo ""
    read -p "Select an option (1-8): " choice
}

# Function to export certificates
export_certs() {
    echo ""
    echo "🔐 Exporting certificates to GCS..."
    ./export-certs-to-gcs.sh
}

# Function to import certificates
import_certs() {
    echo ""
    echo "🔐 Importing certificates from GCS..."
    ./import-certs-from-gcs.sh
}

# Function to create images with GCS certificates
create_images() {
    echo ""
    echo "🖼️ Creating images with GCS certificates..."
    ./create-images-with-gcs-certs.sh
}

# Function to list certificates in GCS
list_certs() {
    echo ""
    echo "📋 Certificates in GCS bucket: gs://$BUCKET_NAME"
    echo "=============================================="
    if gsutil ls gs://$BUCKET_NAME/ >/dev/null 2>&1; then
        gsutil ls -la gs://$BUCKET_NAME/
    else
        echo "❌ GCS bucket not found: gs://$BUCKET_NAME"
        echo "Run option 1 to export certificates first"
    fi
}

# Function to download certificates locally
download_certs() {
    echo ""
    echo "📥 Downloading certificates locally..."
    
    if ! gsutil ls gs://$BUCKET_NAME/ >/dev/null 2>&1; then
        echo "❌ GCS bucket not found: gs://$BUCKET_NAME"
        echo "Run option 1 to export certificates first"
        return
    fi
    
    mkdir -p ssl-certs-local
    
    echo "📥 Downloading HAProxy certificate..."
    if gsutil ls gs://$BUCKET_NAME/haproxy/balancer.svdevops.tech.pem >/dev/null 2>&1; then
        gsutil cp gs://$BUCKET_NAME/haproxy/balancer.svdevops.tech.pem ssl-certs-local/haproxy-balancer.svdevops.tech.pem
        echo "   ✅ HAProxy certificate downloaded"
    else
        echo "   ⚠️  HAProxy certificate not found"
    fi
    
    echo "📥 Downloading Web1 certificates..."
    if gsutil ls gs://$BUCKET_NAME/web1/web1.svdevops.tech.pem >/dev/null 2>&1; then
        gsutil cp gs://$BUCKET_NAME/web1/web1.svdevops.tech.pem ssl-certs-local/web1.svdevops.tech.pem
        gsutil cp gs://$BUCKET_NAME/web1/web1.svdevops.tech.key ssl-certs-local/web1.svdevops.tech.key
        echo "   ✅ Web1 certificates downloaded"
    else
        echo "   ⚠️  Web1 certificates not found"
    fi
    
    echo "📥 Downloading Web2 certificates..."
    if gsutil ls gs://$BUCKET_NAME/web2/web2.svdevops.tech.pem >/dev/null 2>&1; then
        gsutil cp gs://$BUCKET_NAME/web2/web2.svdevops.tech.pem ssl-certs-local/web2.svdevops.tech.pem
        gsutil cp gs://$BUCKET_NAME/web2/web2.svdevops.tech.key ssl-certs-local/web2.svdevops.tech.key
        echo "   ✅ Web2 certificates downloaded"
    else
        echo "   ⚠️  Web2 certificates not found"
    fi
    
    echo ""
    echo "✅ Certificates downloaded to ssl-certs-local/ directory"
}

# Function to test certificate validity
test_certs() {
    echo ""
    echo "🧪 Testing certificate validity..."
    
    # Test HAProxy
    echo "📡 Testing HAProxy certificate..."
    HAPROXY_IP=$(cd infrastructure && terraform output -raw haproxy_external_ip 2>/dev/null || echo "Not deployed")
    if [ "$HAPROXY_IP" != "Not deployed" ]; then
        HTTPS_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" https://balancer.svdevops.tech -k || echo "000")
        if [ "$HTTPS_RESPONSE" = "200" ]; then
            echo "   ✅ HAProxy HTTPS working (200)"
        else
            echo "   ❌ HAProxy HTTPS failed ($HTTPS_RESPONSE)"
        fi
    else
        echo "   ⚠️  HAProxy not deployed"
    fi
    
    # Test Web1
    echo "📡 Testing Web1 certificate..."
    WEB1_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" https://web1.svdevops.tech -k || echo "000")
    if [ "$WEB1_RESPONSE" = "200" ]; then
        echo "   ✅ Web1 HTTPS working (200)"
    else
        echo "   ❌ Web1 HTTPS failed ($WEB1_RESPONSE)"
    fi
    
    # Test Web2
    echo "📡 Testing Web2 certificate..."
    WEB2_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" https://web2.svdevops.tech -k || echo "000")
    if [ "$WEB2_RESPONSE" = "200" ]; then
        echo "   ✅ Web2 HTTPS working (200)"
    else
        echo "   ❌ Web2 HTTPS failed ($WEB2_RESPONSE)"
    fi
}

# Function to show certificate information
show_cert_info() {
    echo ""
    echo "📋 Certificate Information"
    echo "========================="
    
    if [ -f "ssl-certs-local/haproxy-balancer.svdevops.tech.pem" ]; then
        echo "🔐 HAProxy Certificate:"
        openssl x509 -in ssl-certs-local/haproxy-balancer.svdevops.tech.pem -text -noout | grep -E "(Subject:|Issuer:|Not Before:|Not After:)" || echo "   ⚠️  Certificate not readable"
    else
        echo "🔐 HAProxy Certificate: Not found locally"
    fi
    
    if [ -f "ssl-certs-local/web1.svdevops.tech.pem" ]; then
        echo "🔐 Web1 Certificate:"
        openssl x509 -in ssl-certs-local/web1.svdevops.tech.pem -text -noout | grep -E "(Subject:|Issuer:|Not Before:|Not After:)" || echo "   ⚠️  Certificate not readable"
    else
        echo "🔐 Web1 Certificate: Not found locally"
    fi
    
    if [ -f "ssl-certs-local/web2.svdevops.tech.pem" ]; then
        echo "🔐 Web2 Certificate:"
        openssl x509 -in ssl-certs-local/web2.svdevops.tech.pem -text -noout | grep -E "(Subject:|Issuer:|Not Before:|Not After:)" || echo "   ⚠️  Certificate not readable"
    else
        echo "🔐 Web2 Certificate: Not found locally"
    fi
}

# Main menu loop
while true; do
    show_menu
    case $choice in
        1)
            export_certs
            ;;
        2)
            import_certs
            ;;
        3)
            create_images
            ;;
        4)
            list_certs
            ;;
        5)
            download_certs
            ;;
        6)
            test_certs
            ;;
        7)
            show_cert_info
            ;;
        8)
            echo ""
            echo "👋 Goodbye!"
            exit 0
            ;;
        *)
            echo ""
            echo "❌ Invalid option. Please select 1-8."
            ;;
    esac
done
