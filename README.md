# OBG Ansible Deployment Guide

This guide will help you set up and run the OBG deployment using Ansible. Follow these steps carefully to ensure a successful installation.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Installation Steps](#installation-steps)
3. [Running the Deployment](#running-the-deployment)

## Prerequisites

Before you begin, make sure you have the following requirements:

### 1. Java Installation
You need Java 21 installed on your system. Here's how to install it:

```bash
# Update your package list
sudo apt update

# Install Java 21
sudo apt install openjdk-21-jdk
```

To verify the installation, run:
```bash
java -version
```

```bash
/usr/bin/java --version
 ```

You should see output showing Java 21 is installed.

### 2. SSH Setup
The deployment script will automatically install SSH if it's not already installed. However, if you want to verify your SSH setup:

```bash
# Check SSH service status
sudo systemctl status ssh
```

If you see "**Active: inactive (dead)**", start the SSH service:
```bash
sudo systemctl start ssh
```

After starting, check the status again. You should see "**Active: active (running)**".

## Installation Steps

### 1. Clone the Repository
Choose one of these methods to get the code:

**Using SSH (recommended for developers):**
```bash
git clone git@github.com:ADORSYS-GIS/obg-ansible-deployment.git
```

**Using HTTPS (easier for beginners):**
```bash
git clone https://github.com/ADORSYS-GIS/obg-ansible-deployment.git
```

### 2. Prepare Your Environment

After cloning, you'll need to gather some information for the setup:

1. Get your computer's IP address:
```bash
hostname -i
```

2. Get your username:
```bash
whoami
```

You'll need these details for the configuration (you'll be putting them in the **inventory** file).

## Running the Deployment

1. Navigate to the project directory:
```bash
cd obg-ansible-deployment
```

2. Make the script executable:
```bash
chmod +x test.sh
```

3. Run the deployment script:
```bash
./test.sh
```

The script will:
- Check for required software
- Install any missing dependencies
- Configure the necessary settings
- Run the Ansible deployment

## Troubleshooting

If you encounter any issues:
1. Make sure all prerequisites are installed
2. Verify your SSH service is running
3. Check that you have the correct permissions
4. Ensure you're in the correct directory when running the script
5. For Linux(Ubuntu) User, if you run into this error "**FAILED! => {"changed": false, "msg": "Failed to update apt cache: unknown reason"}**", visit this link for more resources on how to reolve it, as it's not a script: https://askubuntu.com/questions/741410/skipping-acquire-of-configured-file-main-binary-i386-packages-as-repository-x

For additional help, please contact the development team.
