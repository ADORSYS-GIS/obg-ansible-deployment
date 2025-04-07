#!/bin/bash
set -euo pipefail

# Check if script is run with sudo
if [ "$EUID" -ne 0 ]; then
    echo "❌ Please run this script with sudo privileges"
    exit 1
fi

echo "🔧 Setting up OBG user and permissions..."

# Function to check if a command exists
check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo "❌ $1 is not installed. Installing now..."
        apt-get update && apt-get install -y "$1"
    else
        echo "✅ $1 is already installed"
    fi
}

# Function to check if a package is installed
check_package() {
    if dpkg -l "$1" 2>/dev/null | grep -q "^ii"; then
        echo "✅ $1 is already installed"
        return 0
    else
        echo "❌ $1 is not installed. Installing now..."
        apt-get update && apt-get install -y "$1"
        return 1
    fi
}

# Function to check if a directory exists and has correct permissions
check_directory() {
    local dir=$1
    local owner=$2
    local perm=$3
    
    if [ -d "$dir" ]; then
        local current_owner=$(stat -c "%U:%G" "$dir")
        local current_perm=$(stat -c "%a" "$dir")
        
        if [ "$current_owner" = "$owner" ] && [ "$current_perm" = "$perm" ]; then
            echo "✅ Directory $dir has correct permissions"
            return 0
        else
            echo "⚠️ Directory $dir needs permission update"
            return 1
        fi
    else
        echo "❌ Directory $dir does not exist"
        return 1
    fi
}

# Function to check if a user is in a group
check_user_group() {
    local user=$1
    local group=$2
    
    if groups "$user" | grep -q "\b$group\b"; then
        echo "✅ User $user is already in group $group"
        return 0
    else
        echo "❌ User $user needs to be added to group $group"
        return 1
    fi
}

# Function to check if SSH key exists
check_ssh_key() {
    local user=$1
    local home_dir=$(getent passwd "$user" | cut -d: -f6)
    
    if [ -f "$home_dir/.ssh/id_rsa" ] && [ -f "$home_dir/.ssh/id_rsa.pub" ]; then
        echo "✅ SSH key already exists for user $user"
        return 0
    else
        echo "❌ SSH key needs to be generated for user $user"
        return 1
    fi
}

# Ensure required commands are installed
check_command "sudo"

# Check and install openssh-server if needed
check_package "openssh-server"

# Create obg user if it doesn't exist
if ! id "obg" &>/dev/null; then
    echo "👤 Creating 'obg' user..."
    useradd -m -s /bin/bash obg
    
    # Prompt for password securely
    while true; do
        echo "🔑 Please enter a password for the 'obg' user:"
        read -s password
        echo
        if [ -z "$password" ]; then
            echo "❌ Password cannot be empty. Please try again."
            continue
        fi
        echo "🔑 Please confirm the password:"
        read -s password_confirm
        echo
        if [ "$password" != "$password_confirm" ]; then
            echo "❌ Passwords do not match. Please try again."
            continue
        fi
        break
    done
    
    echo "obg:$password" | chpasswd
    echo "✅ Password set successfully"
else
    echo "✅ 'obg' user already exists"
fi

# Check and create necessary directories
OBG_HOME=$(getent passwd obg | cut -d: -f6)
for dir in "/opt/obg" "/var/log/obg" "/etc/obg"; do
    check_directory "$dir" "obg:obg" "755" || {
        mkdir -p "$dir"
        chown -R obg:obg "$dir"
        chmod 755 "$dir"
        echo "✅ Created and set permissions for $dir"
    }
done

# Check and add obg user to necessary groups
for group in "sudo" "systemd-journal"; do
    check_user_group "obg" "$group" || {
        usermod -aG "$group" obg
        echo "✅ Added obg user to $group group"
    }
done

# Check and configure sudo access
SUDOERS_FILE="/etc/sudoers.d/obg"
if [ -f "$SUDOERS_FILE" ]; then
    if grep -q "obg ALL=(ALL) NOPASSWD: /bin/systemctl" "$SUDOERS_FILE"; then
        echo "✅ Sudo access already configured"
    else
        echo "⚠️ $SUDOERS_FILE exists but needs update"
        mv "$SUDOERS_FILE" "${SUDOERS_FILE}.bak"
        echo "obg ALL=(ALL) NOPASSWD: /bin/systemctl" | tee "$SUDOERS_FILE" > /dev/null
        chmod 440 "$SUDOERS_FILE"
        echo "✅ Updated sudo access configuration"
    fi
else
    echo "obg ALL=(ALL) NOPASSWD: /bin/systemctl" | tee "$SUDOERS_FILE" > /dev/null
    chmod 440 "$SUDOERS_FILE"
    echo "✅ Created sudo access configuration"
fi

# Check and setup SSH for obg user
check_ssh_key "obg" || {
    echo "🔑 Setting up SSH for 'obg' user..."
    mkdir -p "$OBG_HOME/.ssh"
    chown -R obg:obg "$OBG_HOME/.ssh"
    chmod 700 "$OBG_HOME/.ssh"
    
    sudo -u obg bash -c "ssh-keygen -t rsa -N '' -f '$OBG_HOME/.ssh/id_rsa'"
    cat "$OBG_HOME/.ssh/id_rsa.pub" > "$OBG_HOME/.ssh/authorized_keys"
    chown obg:obg "$OBG_HOME/.ssh/authorized_keys"
    chmod 600 "$OBG_HOME/.ssh/authorized_keys"
    echo "✅ Generated SSH key for obg user"
}

# Check and enable password authentication in SSH config
SSH_CONFIG="/etc/ssh/sshd_config"
if grep -q "PasswordAuthentication yes" "$SSH_CONFIG"; then
    echo "✅ Password authentication already enabled in SSH config"
else
    echo "🔧 Enabling password authentication in SSH config..."
    sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication yes/' "$SSH_CONFIG"
    sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' "$SSH_CONFIG"
    systemctl restart sshd
    echo "✅ Enabled password authentication in SSH config"
fi

echo "✅ All tasks completed successfully!"
echo "📝 You can now run test.sh to deploy services using the 'obg' user."

echo "👤 Switching to 'obg' user now. Type 'exit' to return."
exec sudo -u obg bash