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

### 2. Python Version
The Ansible scripts require **Python 3.10 or higher** to run reliably.

To check your Python version:
```bash
python3 --version
```
If your version is lower than 3.10, install Python 3.10+ using:
```bash
sudo apt install python3.10
```

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

- Get your computer's IP address:
```bash
hostname -I
```
You'll need this for the configuration. Replace **```your-host```** in the **```inventory```** file with the output of the above command.

## Running the Deployment

#### 1. Navigate to the project directory:
```bash
cd obg-ansible-deployment
```

####  2. Run the OBG setup script
```bash
sudo ./setup_obg_user.sh
```
ℹ️ Once the script completes, you will automatically be switched to the obg user inside the project directory.

This script will:
- Ensure necessary dependencies are installed
- Create and configure the obg system user
- Set up SSH access
- Configure sudo access
- Switch to the obg user at the end

#### 3. Set correct file ownership for the **```obg```** user:
Before continuing, make sure the **obg** user has ownership over the project directory. This is required so the **obg** user can execute the deployment script after the setup. <br>
Replace the path below with the correct path to your cloned repository:
```bash
sudo chown -R obg:obg /home/your-username/path-to/obg-ansible-deployment
```

You can get the path by running the following;
```bash
pwd
```

#### 4. Run the deployment script
```bash
chmod +x test.sh
```

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
