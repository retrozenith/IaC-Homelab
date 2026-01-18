# =============================================================================
# Bitwarden Secrets Manager Configuration
# Set BWS_ACCESS_TOKEN environment variable before running terraform
# =============================================================================

variable "bw_secret_proxmox_api_token" {
  description = "Bitwarden secret ID for Proxmox API token"
  type        = string
}

variable "bw_secret_lxc_root_password" {
  description = "Bitwarden secret ID for LXC root password"
  type        = string
}

variable "bw_secret_ssh_public_key" {
  description = "Bitwarden secret ID for SSH public key"
  type        = string
}

# =============================================================================
# Proxmox Connection Variables
# =============================================================================

variable "proxmox_endpoint" {
  description = "Proxmox API endpoint URL"
  type        = string
  default     = "https://192.168.0.26:8006"
}

variable "proxmox_insecure" {
  description = "Skip TLS verification for self-signed certificates"
  type        = bool
  default     = true
}

variable "proxmox_node" {
  description = "Proxmox node name"
  type        = string
  default     = "pve01"
}

# =============================================================================
# Common LXC Configuration
# =============================================================================

variable "lxc_template" {
  description = "LXC template file ID"
  type        = string
  default     = "local:vztmpl/debian-13-standard_13.1-2_amd64.tar.zst"
}

variable "lxc_storage" {
  description = "Proxmox storage for LXC root disks"
  type        = string
  default     = "local-lvm"
}

variable "lxc_gateway" {
  description = "Gateway IP address"
  type        = string
  default     = "192.168.0.1"
}

variable "lxc_bridge" {
  description = "Proxmox network bridge"
  type        = string
  default     = "vmbr0"
}

# =============================================================================
# Storage LXC Configuration
# =============================================================================

variable "storage_lxc_id" {
  description = "Storage LXC container ID"
  type        = number
  default     = 200
}

variable "storage_lxc_ip" {
  description = "Storage LXC static IP with CIDR"
  type        = string
  default     = "192.168.0.101/24"
}

variable "storage_lxc_cores" {
  description = "Storage LXC CPU cores"
  type        = number
  default     = 2
}

variable "storage_lxc_memory" {
  description = "Storage LXC memory in MB"
  type        = number
  default     = 1024
}

# =============================================================================
# Media Stack LXC Configuration
# =============================================================================

variable "media_lxc_id" {
  description = "Media Stack LXC container ID"
  type        = number
  default     = 201
}

variable "media_lxc_ip" {
  description = "Media Stack LXC static IP with CIDR"
  type        = string
  default     = "192.168.0.100/24"
}

variable "media_lxc_cores" {
  description = "Media Stack LXC CPU cores"
  type        = number
  default     = 4
}

variable "media_lxc_memory" {
  description = "Media Stack LXC memory in MB"
  type        = number
  default     = 8192
}

variable "media_lxc_swap" {
  description = "Media Stack LXC swap in MB"
  type        = number
  default     = 2048
}

variable "media_lxc_disk_size" {
  description = "Media Stack LXC root disk size in GB"
  type        = number
  default     = 50
}


# =============================================================================
# Traefik LXC Configuration
# =============================================================================

variable "traefik_lxc_id" {
  description = "Traefik LXC container ID"
  type        = number
  default     = 202
}

variable "traefik_lxc_ip" {
  description = "Traefik LXC static IP with CIDR"
  type        = string
  default     = "192.168.0.254/24"
}

variable "traefik_lxc_cores" {
  description = "Traefik LXC CPU cores"
  type        = number
  default     = 2
}

variable "traefik_lxc_memory" {
  description = "Traefik LXC memory in MB"
  type        = number
  default     = 2048
}

# =============================================================================
# Bitwarden Secret IDs for Ansible
# =============================================================================

variable "bw_secret_smb_password" {
  description = "Bitwarden secret ID for SMB user password"
  type        = string
  default     = ""
}

variable "bw_secret_wireguard_key" {
  description = "Bitwarden secret ID for WireGuard private key"
  type        = string
  default     = ""
}

variable "bw_secret_streamystats_db" {
  description = "Bitwarden secret ID for StreamyStats DB password"
  type        = string
  default     = ""
}

variable "bw_secret_streamystats_session" {
  description = "Bitwarden secret ID for StreamyStats session secret"
  type        = string
  default     = ""
}
