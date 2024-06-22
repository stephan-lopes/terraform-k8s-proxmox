terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "3.0.1-rc3"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.5"
    }
  }
}

provider "proxmox" {

  pm_api_url          = var.proxmox_credentials.proxmox_url
  pm_api_token_id     = var.proxmox_credentials.username
  pm_api_token_secret = var.proxmox_credentials.token

  pm_tls_insecure = true
}
