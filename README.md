# IaC-pve

Infrastructure as Code (IaC) repository for managing a Proxmox VE homelab environment using Terraform and Ansible.

## Architecture

This project uses a two-stage deployment strategy:

1.  **Terraform**: Provisions the infrastructure resources on Proxmox.
    - Creates LXC containers for Storage, Docker Services, Traefik, and Monitoring.
    - Configures resource allocation (CPU, RAM, Disk).
    - Manages secret injection via Bitwarden Secrets Manager (`bws`).

2.  **Ansible**: Configures the software inside the provisioned containers.
    - Installs required packages (Docker, Samba, default utils).
    - Deploys application configurations (Traefik static/dynamic conf, Docker Compose, Prometheus/Grafana).
    - Manages file mounts and user permissions.

## Prerequisites

- **Proxmox VE >= 9.0**
- **Terraform >= 1.0**
- **Ansible >= 2.10**
- **Bitwarden Secrets CLI (`bws`)**: Required for injecting secrets during Terraform runs.
- **ssh-agent**: Must be running with the correct private key loaded for Ansible connections.

## Directory Structure

- **`terraform/`**: Terraform configurations (`.tf` files).
- **`ansible/`**: Ansible project root.
  - `inventory/`: Host definitions (`hosts.yml`).
  - `playbooks/`: Top-level playbooks for deploying disparate systems.
  - `roles/`: Reusable Ansible roles for specific tasks (e.g., `docker`, `traefik`).
  - `group_vars/`: Global configuration variables (`all.yml`).

## Common Commands

The project includes a `Makefile` to simplify common operations.

### Terraform

```bash
make tf-init     # Initialize Terraform
make tf-plan     # Plan changes
make tf-apply    # Apply changes (provisions LXCs)
make tf-destroy  # Destroy resources
```

### Ansible

```bash
make site        # Run the full site playbook (configures everything)
make storage     # Configure only the Storage LXC
make docker-services # Configure only Docker Services
make traefik     # Configure only Traefik
make monitoring  # Configure only Monitoring
```

### Validation

```bash
make lint        # Run linters (Terraform fmt + Ansible lint)
make test        # Run tests (Terraform validate)
```
