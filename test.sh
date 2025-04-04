#!/bin/bash
set -euo pipefail

echo "🚀 Starting Ansible Deployment Test..."

# Function to check if a command exists
check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo "❌ $1 is not installed. Installing now..."
        sudo apt-get update && sudo apt-get install -y "$1"
    else
        echo "✅ $1 is already installed"
    fi
}

# Function to check if a package is installed
check_package() {
    if ! dpkg -l "$1" 2>/dev/null | grep -q "^ii"; then
        echo "❌ $1 is not installed. Installing now..."
        sudo apt-get update && sudo apt-get install -y "$1"
    else
        echo "✅ $1 is already installed"
    fi
}

# Function to check if a file exists
check_file() {
    if [ ! -f "$1" ]; then
        echo "❌ Required file '$1' not found!"
        exit 1
    else
        echo "✅ Found required file '$1'"
    fi
}

# Ensure required commands are installed
check_command "sshpass"
check_command "ansible"

# Ensure required packages are installed
check_package "openssh-server"
check_package "python3-psycopg2"

# Define inventory file location
INVENTORY_FILE="inventory"
PLAYBOOK_FILE="playbook.yml"

# Check for required files
check_file "$INVENTORY_FILE"
check_file "$PLAYBOOK_FILE"

# Clear any existing SSH fingerprint
echo "🧹 Cleaning up SSH fingerprints..."
TARGET_HOST=$(grep -v '^\[.*\]' "$INVENTORY_FILE" | grep -v '^$' | head -n1 | awk '{print $1}')
if [ -n "$TARGET_HOST" ]; then
    ssh-keygen -f "$HOME/.ssh/known_hosts" -R "$TARGET_HOST"
else
    echo "⚠️ Warning: Could not determine target host from inventory file"
fi

# Run the Ansible playbook
echo "🔧 Running Ansible Playbook..."
echo "📝 Using inventory file: $INVENTORY_FILE"
echo "📝 Using playbook file: $PLAYBOOK_FILE"

if ansible-playbook -i "$INVENTORY_FILE" "$PLAYBOOK_FILE" --ask-pass --ask-become-pass; then
    echo "✅ Deployment completed successfully!"
else
    echo "❌ Deployment failed! Please check the error messages above."
    exit 1
fi
