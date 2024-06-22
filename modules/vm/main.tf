locals {
  vm_cpus   = var.vm_config_stats.cpus
  vm_memory = var.vm_config_stats.memory

  vm_count = var.vm_count

  vm_private_key = var.ssh_private_key
  vm_public_key  = var.ssh_public_key

  vm_image_name = "kubernetes-1.30-latest"
}

resource "proxmox_vm_qemu" "this" {

  count = local.vm_count

  name        = "srv-${var.vm_type}-${count.index + 1}"
  desc        = "Este é a máquina configurada para executar o kubernetes, seja como control plane, ou como worker"
  vmid        = var.initial_vm_id + count.index
  target_node = "proxmox"

  tablet = false
  agent  = 1

  boot       = "order=scsi0;net0;ide0"
  clone      = local.vm_image_name
  full_clone = true
  cores      = local.vm_cpus
  sockets    = 1
  cpu        = "host"
  memory     = local.vm_memory

  ipconfig0 = "ip=dhcp"
  os_type   = "cloud-init"

  network {
    bridge = "vmbr1"
    model  = "virtio"
  }

  disks {
    ide {
      ide0 {
        cloudinit {
          storage = "local-lvm"
        }
      }
    }
    scsi {
      scsi0 {
        disk {
          size    = "30G"
          storage = "local-lvm"
        }
      }
    }
  }

  define_connection_info = true
  ssh_user               = "kubernetes"
  ssh_private_key        = local.vm_private_key

  sshkeys = local.vm_public_key

  connection {
    type        = "ssh"
    user        = self.ssh_user
    password    = self.ssh_user
    private_key = self.ssh_private_key
    host        = self.ssh_host
    port        = "22"
  }

  provisioner "remote-exec" {
    inline = ["ip a"]
  }
}

output "ssh_user" {
  value = [for vm in proxmox_vm_qemu.this : vm.ssh_user]
}

output "ssh_host" {
  value = [for vm in proxmox_vm_qemu.this : vm.ssh_host]
}
