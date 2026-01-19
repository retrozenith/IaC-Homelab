terraform {
  required_version = ">= 1.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.50.0"
    }
    external = {
      source  = "hashicorp/external"
      version = ">= 2.0.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0.0"
    }
  }
}

# =============================================================================
# Fetch Secrets from Bitwarden using bws CLI
# Requires: bws CLI installed and BWS_ACCESS_TOKEN environment variable set
# =============================================================================

data "external" "bw_proxmox_api_token" {
  program = ["bash", "-c", "bws secret get ${var.bw_secret_proxmox_api_token} --output json | jq '{value: .value}'"]
}

data "external" "bw_lxc_root_password" {
  program = ["bash", "-c", "bws secret get ${var.bw_secret_lxc_root_password} --output json | jq '{value: .value}'"]
}

data "external" "bw_ssh_public_key" {
  program = ["bash", "-c", "bws secret get ${var.bw_secret_ssh_public_key} --output json | jq '{value: .value}'"]
}

# =============================================================================
# Proxmox Provider (using secrets from Bitwarden)
# =============================================================================
provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = data.external.bw_proxmox_api_token.result.value
  insecure  = var.proxmox_insecure

  ssh {
    agent    = true
    username = "root"
  }
}

# =============================================================================
# Storage LXC - Samba file server
# =============================================================================
resource "proxmox_virtual_environment_container" "storage" {
  node_name   = var.proxmox_node
  vm_id       = var.storage_lxc_id
  description = "<b>Storage LXC</b> - Samba file server for media and general storage<br><br><b>Shares:</b><br>• <code>&#92;&#92;${split("/", var.storage_lxc_ip)[0]}&#92;media</code><br>• <code>&#92;&#92;${split("/", var.storage_lxc_ip)[0]}&#92;downloads</code><br>• <code>&#92;&#92;${split("/", var.storage_lxc_ip)[0]}&#92;backups</code><br><br><b>macOS/Linux:</b> <code>smb://${split("/", var.storage_lxc_ip)[0]}</code>"

  operating_system {
    template_file_id = var.lxc_template
    type             = "debian"
  }

  initialization {
    hostname = "storage"

    ip_config {
      ipv4 {
        address = var.storage_lxc_ip
        gateway = var.lxc_gateway
      }
    }

    dns {
      domain  = "local"
      servers = ["1.1.1.1", "8.8.8.8"]
    }

    user_account {
      keys     = [data.external.bw_ssh_public_key.result.value]
      password = data.external.bw_lxc_root_password.result.value
    }
  }

  cpu {
    cores = var.storage_lxc_cores
  }

  memory {
    dedicated = var.storage_lxc_memory
    swap      = 1024
  }

  disk {
    datastore_id = var.lxc_storage
    size         = 8
  }

  network_interface {
    name   = "eth0"
    bridge = var.lxc_bridge
  }

  unprivileged = false

  features {
    # Enabled via Ansible due to Terraform permissions issues
  }

  lifecycle {
    ignore_changes = [features, unprivileged]
  }

  started       = true
  start_on_boot = true

  tags = ["storage", "samba", "managed-by-terraform"]
}

# =============================================================================
# Docker Services LXC - Docker services
# =============================================================================
resource "proxmox_virtual_environment_container" "docker_services" {
  node_name   = var.proxmox_node
  vm_id       = var.docker_services_lxc_id
  description = "<b>Docker Services LXC</b> - Docker services for media management<br><br><b>Services:</b><br>• <a href='http://${split("/", var.docker_services_lxc_ip)[0]}:8096' target='_blank'>Jellyfin</a> :8096<br>• <a href='http://${split("/", var.docker_services_lxc_ip)[0]}:5055' target='_blank'>Jellyseerr</a> :5055<br>• <a href='http://${split("/", var.docker_services_lxc_ip)[0]}:3000' target='_blank'>StreamyStats</a> :3000<br>• <a href='http://${split("/", var.docker_services_lxc_ip)[0]}:8989' target='_blank'>Sonarr</a> :8989<br>• <a href='http://${split("/", var.docker_services_lxc_ip)[0]}:7878' target='_blank'>Radarr</a> :7878<br>• <a href='http://${split("/", var.docker_services_lxc_ip)[0]}:9696' target='_blank'>Prowlarr</a> :9696<br>• <a href='http://${split("/", var.docker_services_lxc_ip)[0]}:6868' target='_blank'>Profilarr</a> :6868<br>• <a href='http://${split("/", var.docker_services_lxc_ip)[0]}:8080' target='_blank'>qBittorrent</a> :8080<br>• <a href='http://${split("/", var.docker_services_lxc_ip)[0]}:7476' target='_blank'>Qui</a> :7476 (qBittorrent UI)"

  depends_on = [proxmox_virtual_environment_container.storage]

  operating_system {
    template_file_id = var.lxc_template
    type             = "debian"
  }

  initialization {
    hostname = "docker-services"

    ip_config {
      ipv4 {
        address = var.docker_services_lxc_ip
        gateway = var.lxc_gateway
      }
    }

    user_account {
      keys     = [data.external.bw_ssh_public_key.result.value]
      password = data.external.bw_lxc_root_password.result.value
    }

    dns {
      domain  = "local"
      servers = ["1.1.1.1", "8.8.8.8"]
    }
  }

  cpu {
    cores = var.docker_services_lxc_cores
  }

  memory {
    dedicated = var.docker_services_lxc_memory
    swap      = var.docker_services_lxc_swap
  }

  disk {
    datastore_id = var.lxc_storage
    size         = var.docker_services_lxc_disk_size
  }

  network_interface {
    name   = "eth0"
    bridge = var.lxc_bridge
  }

  # Start as unprivileged, Ansible will reconfigure for Docker
  unprivileged = true

  lifecycle {
    ignore_changes = [features, unprivileged]
  }

  started       = true
  start_on_boot = true

  tags = ["media", "docker", "managed-by-terraform"]
}

# =============================================================================
# Traefik LXC - Reverse Proxy
# =============================================================================
resource "proxmox_virtual_environment_container" "traefik" {
  node_name   = var.proxmox_node
  vm_id       = var.traefik_lxc_id
  description = "<b>Traefik LXC</b> - Reverse Proxy with automatic SSL<br><br><b>Services:</b><br>• <a href='http://${split("/", var.traefik_lxc_ip)[0]}:8080' target='_blank'>Dashboard</a> :8080"

  operating_system {
    template_file_id = var.lxc_template
    type             = "debian"
  }

  initialization {
    hostname = "traefik"

    ip_config {
      ipv4 {
        address = var.traefik_lxc_ip
        gateway = var.lxc_gateway
      }
    }

    user_account {
      keys     = [data.external.bw_ssh_public_key.result.value]
      password = data.external.bw_lxc_root_password.result.value
    }

    dns {
      domain  = "local"
      servers = ["1.1.1.1", "8.8.8.8"]
    }
  }

  cpu {
    cores = var.traefik_lxc_cores
  }

  memory {
    dedicated = var.traefik_lxc_memory
    swap      = 512
  }

  disk {
    datastore_id = var.lxc_storage
    size         = 8
  }

  network_interface {
    name   = "eth0"
    bridge = var.lxc_bridge
  }

  # Start as unprivileged, Ansible may reconfigure if needed
  unprivileged = true

  lifecycle {
    ignore_changes = [features, unprivileged]
  }

  started       = true
  start_on_boot = true

  tags = ["traefik", "proxy", "docker", "managed-by-terraform"]
}

# =============================================================================
# Monitoring LXC - Grafana + Prometheus
# =============================================================================
resource "proxmox_virtual_environment_container" "monitoring" {
  node_name   = var.proxmox_node
  vm_id       = var.monitoring_lxc_id
  description = "<b>Monitoring LXC</b> - Grafana + Prometheus monitoring stack<br><br><b>Services:</b><br>• <a href='http://${split("/", var.monitoring_lxc_ip)[0]}:3000' target='_blank'>Grafana</a> :3000<br>• <a href='http://${split("/", var.monitoring_lxc_ip)[0]}:9090' target='_blank'>Prometheus</a> :9090"

  operating_system {
    template_file_id = var.lxc_template
    type             = "debian"
  }

  initialization {
    hostname = "monitoring"

    ip_config {
      ipv4 {
        address = var.monitoring_lxc_ip
        gateway = var.lxc_gateway
      }
    }

    user_account {
      keys     = [data.external.bw_ssh_public_key.result.value]
      password = data.external.bw_lxc_root_password.result.value
    }

    dns {
      domain  = "local"
      servers = ["1.1.1.1", "8.8.8.8"]
    }
  }

  cpu {
    cores = var.monitoring_lxc_cores
  }

  memory {
    dedicated = var.monitoring_lxc_memory
    swap      = 512
  }

  disk {
    datastore_id = var.lxc_storage
    size         = 20
  }

  network_interface {
    name   = "eth0"
    bridge = var.lxc_bridge
  }

  unprivileged = true

  lifecycle {
    ignore_changes = [features, unprivileged]
  }

  started       = true
  start_on_boot = true

  tags = ["monitoring", "grafana", "prometheus", "docker", "managed-by-terraform"]
}

# Wait for LXCs to be ready
# We sleep to ensure the LXC networking stack is fully up before Ansible tries to connect
resource "null_resource" "wait_for_lxc" {
  depends_on = [
    proxmox_virtual_environment_container.storage,
    proxmox_virtual_environment_container.docker_services,
    proxmox_virtual_environment_container.traefik,
    proxmox_virtual_environment_container.monitoring
  ]

  provisioner "local-exec" {
    command = "sleep 30"
  }
}
