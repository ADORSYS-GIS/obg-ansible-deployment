#!/bin/bash
set -euo pipefail

# Function to check if a command exists
check_command() {
    if ! command -v "$1" &> /dev/null; then
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

# Ensure podman and pipx or pip are installed
check_command "podman"
check_command "python3"
check_command "pip"
check_command "python3-venv"

# Ensure pipx or fallback to pip install of ansible-core
if command -v pipx &> /dev/null; then
    echo "✅ pipx is already installed"
else
    echo "📦 Installing pipx..."
    python3 -m pip install --user pipx
    python3 -m pipx ensurepath
    export PATH="$HOME/.local/bin:$PATH"
fi

# Install or upgrade Ansible (via pipx if available)
if command -v pipx &> /dev/null; then
    echo "📦 Installing latest ansible-core using pipx..."
    pipx install ansible --force
    export PATH="$HOME/.local/bin:$PATH"
else
    echo "⚠️ pipx not found, falling back to pip install"
    python3 -m pip install --user --upgrade ansible
    export PATH="$HOME/.local/bin:$PATH"
fi

# Verify Ansible version
echo "🔍 Ansible version:"
ansible --version

# remove previously created container
if podman ps -a --format '{{.Names}}' | grep -q '^ansible-obg-test$'; then
  echo "🧹 Removing existing container ansible-obg-test"
  podman rm -f ansible-obg-test
fi

# Build our image
podman build -f Containerfile -t ansible-obg-test

# Run in background (-d) with systemd init
podman run \
	--rm \
	--name ansible-obg-test \
	-p 127.0.0.1:8022:22 \
	-p 127.0.0.1:8085:8085 \
	-p 127.0.0.1:8086:8086 \
	--systemd=always \
	-d localhost/ansible-obg-test sh -c "exec /usr/sbin/init --show-status"

# Print to log that container is running
podman ps

# Clear out fingerprint from any past runs
ssh-keygen -f "$HOME/.ssh/known_hosts" -R "[127.0.0.1]:8022"

echo "🚀 Starting Ansible Deployment Test..."

# Define inventory and playbook files
INVENTORY_FILE="inventories/inventory-local"
PLAYBOOK_FILE="playbook.yml"

# Check for required files
check_file "$INVENTORY_FILE"
check_file "$PLAYBOOK_FILE"

# Clean SSH fingerprint
echo "🧹 Cleaning up SSH fingerprints..."
TARGET_HOST=$(grep -v '^\[.*\]' "$INVENTORY_FILE" | grep -v '^$' | head -n1 | awk '{print $1}')
if [ -n "$TARGET_HOST" ]; then
    ssh-keygen -f "$HOME/.ssh/known_hosts" -R "$TARGET_HOST"
else
    echo "⚠️ Warning: Could not determine target host from inventory file"
fi

# Clean up post-installation marker file if it exists
if [ -f /etc/obg/.postinst_done ]; then
    echo "🧹 Removing /etc/obg/.postinst_done"
    sudo rm -f /etc/obg/.postinst_done
fi

# Run the Ansible playbook
echo "🔧 Running Ansible Playbook..."
echo "📝 Using inventory file: $INVENTORY_FILE"
echo "📝 Using playbook file: $PLAYBOOK_FILE"

if ansible-playbook -vv -i "$INVENTORY_FILE" "$PLAYBOOK_FILE"; then
    echo "✅ Deployment completed successfully!"
else
    echo "❌ Deployment failed! Please check the error messages above."
    exit 1
fi
