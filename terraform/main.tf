terraform {
  required_version = ">= 1.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.50.0"
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
  description = "Storage LXC - Samba file server for media and general storage"

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

  started       = true
  start_on_boot = true

  tags = ["storage", "samba", "managed-by-terraform"]
}

# =============================================================================
# Media Stack LXC - Docker services
# =============================================================================
resource "proxmox_virtual_environment_container" "media_stack" {
  node_name   = var.proxmox_node
  vm_id       = var.media_lxc_id
  description = "Media Stack LXC - Jellyfin, *arr suite, qBittorrent"

  depends_on = [proxmox_virtual_environment_container.storage]

  operating_system {
    template_file_id = var.lxc_template
    type             = "debian"
  }

  initialization {
    hostname = "media-stack"

    ip_config {
      ipv4 {
        address = var.media_lxc_ip
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
    cores = var.media_lxc_cores
  }

  memory {
    dedicated = var.media_lxc_memory
    swap      = var.media_lxc_swap
  }

  disk {
    datastore_id = var.lxc_storage
    size         = var.media_lxc_disk_size
  }

  network_interface {
    name   = "eth0"
    bridge = var.lxc_bridge
  }

  # Start as unprivileged, Ansible will reconfigure for Docker
  unprivileged = true

  started       = true
  start_on_boot = true

  tags = ["media", "docker", "managed-by-terraform"]
}

# Wait for LXCs to be ready
resource "null_resource" "wait_for_lxc" {
  depends_on = [
    proxmox_virtual_environment_container.storage,
    proxmox_virtual_environment_container.media_stack
  ]

  provisioner "local-exec" {
    command = "sleep 30"
  }
}
