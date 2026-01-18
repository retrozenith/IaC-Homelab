# =============================================================================
# Storage LXC Outputs
# =============================================================================

output "storage_lxc_id" {
  description = "Storage LXC container ID"
  value       = proxmox_virtual_environment_container.storage.vm_id
}

output "storage_lxc_ip" {
  description = "Storage LXC IP address"
  value       = split("/", var.storage_lxc_ip)[0]
}

# =============================================================================
# Media Stack LXC Outputs
# =============================================================================

output "media_lxc_id" {
  description = "Media Stack LXC container ID"
  value       = proxmox_virtual_environment_container.media_stack.vm_id
}

output "media_lxc_ip" {
  description = "Media Stack LXC IP address"
  value       = split("/", var.media_lxc_ip)[0]
}

# =============================================================================
# Traefik LXC Outputs
# =============================================================================

output "traefik_lxc_id" {
  description = "Traefik LXC container ID"
  value       = proxmox_virtual_environment_container.traefik.vm_id
}

output "traefik_lxc_ip" {
  description = "Traefik LXC IP address"
  value       = split("/", var.traefik_lxc_ip)[0]
}

# =============================================================================
# Monitoring LXC Outputs
# =============================================================================

output "monitoring_lxc_id" {
  description = "Monitoring LXC container ID"
  value       = proxmox_virtual_environment_container.monitoring.vm_id
}

output "monitoring_lxc_ip" {
  description = "Monitoring LXC IP address"
  value       = split("/", var.monitoring_lxc_ip)[0]
}

# =============================================================================
# Bitwarden Secret IDs (for Ansible)
# =============================================================================

output "bw_secret_ids" {
  description = "Bitwarden secret IDs to pass to Ansible"
  value = {
    smb_password         = var.bw_secret_smb_password
    wireguard_key        = var.bw_secret_wireguard_key
    streamystats_db      = var.bw_secret_streamystats_db
    streamystats_session = var.bw_secret_streamystats_session
  }
  sensitive = true
}

# =============================================================================
# Ansible Inventory
# =============================================================================

output "ansible_inventory" {
  description = "Ansible inventory content"
  value       = <<-EOT
    all:
      vars:
        bw_access_token: "{{ lookup('env', 'BWS_ACCESS_TOKEN') }}"
      children:
        storage:
          hosts:
            storage-lxc:
              ansible_host: ${split("/", var.storage_lxc_ip)[0]}
              ansible_user: root
              ansible_python_interpreter: /usr/bin/python3
        media:
          hosts:
            media-stack:
              ansible_host: ${split("/", var.media_lxc_ip)[0]}
              ansible_user: root
              ansible_python_interpreter: /usr/bin/python3
              storage_server: ${split("/", var.storage_lxc_ip)[0]}
        traefik:
          hosts:
            traefik:
              ansible_host: ${split("/", var.traefik_lxc_ip)[0]}
              ansible_user: root
              ansible_python_interpreter: /usr/bin/python3
        monitoring:
          hosts:
            monitoring:
              ansible_host: ${split("/", var.monitoring_lxc_ip)[0]}
              ansible_user: root
              ansible_python_interpreter: /usr/bin/python3
  EOT
}
