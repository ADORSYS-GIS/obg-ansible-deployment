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

check_file() {
    if [ ! -f "$1" ]; then
        echo "❌ Required file '$1' not found!"
        exit 1
    else
        echo "✅ Found required file '$1'"
    fi
}

check_ansible_version() {
    local min_version="2.14.0"
    if command -v ansible &> /dev/null; then
        local current_version=$(ansible --version | head -n1 | awk '{print $3}' | tr -d '[]')
        if [ "$(printf '%s\n' "$min_version" "$current_version" | sort -V | head -n1)" = "$min_version" ]; then
            echo "✅ Ansible $current_version is already installed (meets minimum requirement of $min_version)"
            return 0
        else
            echo "❌ Ansible $current_version is installed but does not meet minimum requirement of $min_version"
        fi
    else
        echo "❌ Ansible is not installed"
    fi
    return 1
}

install_ansible_with_apt() {
    echo "📦 Installing Ansible using APT with PPA..."
    sudo apt-get update
    sudo apt-get install -y software-properties-common
    sudo apt-add-repository -y ppa:ansible/ansible
    sudo apt-get update
    sudo apt-get install -y ansible
}

check_command "podman"

if ! check_ansible_version; then
    install_ansible_with_apt
    check_ansible_version || { echo "❌ Failed to install a suitable Ansible version"; exit 1; }
fi

echo "🔍 Ansible version:"
ansible --version || "$HOME/.local/bin/ansible" --version

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
	--privileged \
	-p 127.0.0.1:8022:22 \
	-p 127.0.0.1:8085:8085 \
	-p 127.0.0.1:8086:8086 \
	-p 127.0.0.1:48080:48080 \
	-p 127.0.0.1:38080:38080 \
	-p 127.0.0.1:8089:8089 \
	-p 127.0.0.1:8094:8094 \
	-p 127.0.0.1:8090:8090 \
	-p 127.0.0.1:8093:8093 \
	-p 127.0.0.1:4207:4207 \
        -p 127.0.0.1:4206:4206 \
        -p 127.0.0.1:4205:4205 \
        -p 127.0.0.1:4400:4400 \
	-v $PWD/consent-management:$PWD/consent-management:Z \
	--systemd=always \
	-d localhost/ansible-obg-test sh -c "exec /usr/sbin/init --show-status"

# Print to log that container is running
podman ps

echo "📦 Installing Ansible community.general collection inside the container..."
podman exec ansible-obg-test ansible-galaxy collection install community.general

# Clear out fingerprint from any past runs
ssh-keygen -f "$HOME/.ssh/known_hosts" -R "[127.0.0.1]:8022"

echo "🚀 Starting Ansible Deployment Test..."

# Define inventory and playbook files
INVENTORY_FILE="inventories/inventory-local"
PLAYBOOK_FILE="playbooks/<your-playbook>"

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

echo "🔧 Running Ansible Playbook..."
echo "📝 Using inventory file: $INVENTORY_FILE"
echo "📝 Using playbook file: $PLAYBOOK_FILE"

if ansible-playbook -vv -i "$INVENTORY_FILE" "$PLAYBOOK_FILE"; then
    echo "✅ Deployment completed successfully!"
else
    echo "❌ Deployment failed! Please check the error messages above."
    exit 1
fi
