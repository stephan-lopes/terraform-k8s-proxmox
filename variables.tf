variable "proxmox_credentials" {
  description = "proxmox-credentials"
  type = object({
    username    = string
    token       = string
    proxmox_url = string
  })
  sensitive = true
}

variable "config" {
  type = object({
    vm_count_control_plane = number
  })
}
