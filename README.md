# OBG Ansible Deployment Guide

This guide will help you set up and run the OBG deployment using Ansible. Follow these steps carefully to ensure a successful installation.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Installation Steps](#installation-steps)
3. [Running the Deployment](#running-the-deployment)
4. [Configuration Reference](#configuration-reference)

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

### 3. SSH Setup
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

You'll need this for the configuration. Replace **`your-host`** in the **`inventory`** file with the output of the above command.

## Running the Deployment

### 1. Navigate to the project directory:
```bash
cd obg-ansible-deployment
```

### 2. Run the deployment script:
```bash
chmod +x test.sh
./test.sh
```

The script will:
- Check for required software
- Install any missing dependencies
- Configure the necessary settings
- Run the Ansible deployment

---

## Configuration Reference

### QWAC Certificate Configuration (PKCS#12)

In `application.yml.j2`, the `protocol.xs2a.pkcs12` section configures the QWAC (Qualified Website Authentication Certificate) certificate:

```yaml
protocol:
  xs2a:
    pkcs12:
      keystore: "/absolute/or/relative/path/to/qwac-certificate.p12"
      password: "your-keystore-password"
```

**Details:**

- **keystore**: Path to the `.p12` QWAC certificate file.  
  🔐 **Important**: The customer must mount or copy the certificate file to the specified path during deployment.

- **password**: Password used to unlock the `.p12` keystore. This must match the password used when creating the keystore.

---

### OPBA URL Configuration

In `application.yml.j2`, the `opba` section defines various URLs used by the system:

```yaml
opba:
  base-url: {{ opba_base_url }}
  fintech-client-base-url: {{ fintech_base_url }}
  fintech-ui-url: {{ fintech_ui_url }}
  piis-ui-url: {{ piis_ui_url }}
```

**Details:**

- **base-url**: Base URL of the OPBA backend server. This is the main entry point for all backend APIs and services.

- **fintech-client-base-url**: The backend URL for the Fintech Client, which interacts with OPBA during TPP authentication, consent, and payment flows.

- **fintech-ui-url**: The public URL of the Fintech web UI. End-users will use this frontend to view, approve, or reject consent/payment actions.

- **piis-ui-url**: The public URL of the PIIS UI (Payment Instrument Issuer Service). This is used for interacting with flows that require payment instrument verification.

Note:
The actual values for the above URLs are provided in the Ansible configuration under
`roles/obg/vars/main.yml`.


### Admin API Credentials
To access the OPBA Admin API, use the following default credentials:

```yml
username: Aladdin
password: OpenSesame
```
These credentials can be used to log in to the Admin API dashboard for managing consents, clients, and system configurations.

---

## Troubleshooting

If you encounter any issues:
1. Make sure all prerequisites are installed
2. Verify your SSH service is running
3. Check that you have the correct permissions
4. Ensure you're in the correct directory when running the script
5. For Linux (Ubuntu) users, if you run into this error:
   ```
   FAILED! => {"changed": false, "msg": "Failed to update apt cache: unknown reason"}
   ```
   Refer to this resource for help resolving it:  
   https://askubuntu.com/questions/741410/skipping-acquire-of-configured-file-main-binary-i386-packages-as-repository-x

For additional help, please contact the development team.
