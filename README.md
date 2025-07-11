# OBG Ansible Deployment Guide

This guide will help you set up and run the OBG and xs2a deployments using Ansible. Follow these steps carefully to ensure a successful installation and execution.

## Table of Contents

1. [Installation Steps](#installation-steps)
2. [Running the Deployment](#running-the-deployment)
3. [Configuration Reference](#configuration-reference)

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

### Prepare Your Environment

#### A - Inventories
The repository includes two inventory files in the `inventories` directory:

1. **`inventory`**: This is the default inventory file used for remote deployments. It contains placeholders for host-specific variables that need to be customized for your environment.
2. **`inventory-local`**: This inventory file is specifically designed for local deployments. It is pre-configured with settings suitable for running the deployment on the local machine.

To prepare your environment:

1. Choose the appropriate inventory file based on your deployment scenario:
   - For remote deployments, modify the `inventory` file.
   - For local deployments, you can use the `inventory-local` file as it is, or modify it if needed.

2. To use the `inventory` file for remote deployments:
   - Get your target machine's IP address:
     ```bash
     hostname -I
     ```
   - Replace **`your-host`** in the `inventory` file with the output of the above command.

3. To use `inventory-local` for local deployments, no changes are required unless you have specific local configurations.

By selecting and configuring the appropriate inventory file, you ensure that the deployment is tailored to your specific environment.

#### B - Playbooks

The repository includes various playbook files in the `playbooks` directory:

1. **`obg.yml`**: This playbook file is specifically designed for the deployment of the OBG components.
2. **`xs2a.yml`**: This playbook file is specifically designed for the deployment of the XS2A components.
3. **`deploy-all.yml`**: This is the playbook file specifically designed for the deployment of all the components in one go.

To prepare your environment:

1. Choose the appropriate playbook file based on your deployment scenario:
   - For OBG deployments, use the `obg.yml` file.
   - For XS2A deployments, use the `xs2a.yml` file.
   - For deploying all components, use the `deploy-all.yml` file.

2. To use any of the above files for your desired deployment:
   - Navigate to the project directory, and modify the `test.sh` script - Line 94, replacing `<your-playbook>` with your desired playbook:
     ```bash
     PLAYBOOK_FILE="playbooks/<your-playbook>"
     ```
By selecting and configuring the appropriate playbook file, you ensure that the deployment is tailored to your specific environment.

#### C - CMS-Standalone-Service Path Configuration

Navigate to the root of the project, and run the following command to get the current working directory path:
```bash
pwd
```

Then, edit the `roles/cms-standalone-service/tasks/main.yml` file (Line 115) and replace `<path/to/your/local/repo>` with the output of the above command. For example:
```bash
/home/john/obg-ansible-deployment/
```

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

The `test.sh` script automates the deployment process by performing the following steps:
1. **Dependency Check**: Verifies that `podman` is installed. If not, it installs it using `apt-get`.
2. **Container Management**: Removes any existing `ansible-obg-test` container to ensure a clean environment.
3. **Image Build**: Builds a Podman image using the `Containerfile` provided in the repository.
4. **Container Execution**: Runs the built image in a container named `ansible-obg-test`, mapping necessary ports and configuring it to run with systemd init.
5. **Ansible Deployment**:
   - Checks for the presence of required Ansible commands and files.
   - Uses the `inventory-local` file for local deployments or allows specification of a different inventory file.
   - Executes the Ansible playbook (`playbook.yml`) against the selected inventory.
6. **Deployment Verification**: Confirms the success or failure of the Ansible deployment.

By running this script, you ensure that all necessary components are installed, configured, and deployed correctly.

---

## Configuration Reference

### QWAC Certificate Configuration

In `application.yml.j2`, the `protocol.xs2a.pkcs12` section configures the QWAC (Qualified Website Authentication Certificate) certificate:

```yaml
protocol:
  xs2a:
    pkcs12:
      keystore: sample-qwac.keystore
      password: password
```

**Details:**

- **keystore**: The `sample-qwac.keystore` file is included in the repository at `roles/obg/templates/sample-qwac.keystore`, and will hold the certificate.
- **password**: The password to access the keystore is set to `"password"`. This should be replaced with the password used when creating the keystore.

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

⚠️ Important: For production environments, always replace default credentials with secure, environment-specific values.

---

For additional help, please contact the development team.
