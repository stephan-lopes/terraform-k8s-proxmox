resource "tls_private_key" "ed25519-tls-private-key" {
  algorithm = "ED25519"
}

module "control_plane" {
  source = "./modules/vm"

  vm_count = var.config.vm_count_control_plane

  ssh_private_key = tls_private_key.ed25519-tls-private-key.private_key_openssh
  ssh_public_key  = tls_private_key.ed25519-tls-private-key.public_key_openssh
  initial_vm_id   = 6000
  vm_type         = "control-plane"

}

## KUBEADM INIT
resource "null_resource" "kubeadm_init" {

  depends_on = [module.control_plane]

  count = var.config.vm_count_control_plane > 0 ? 1 : 0

  provisioner "remote-exec" {
    inline = [
      "sudo kubeadm init --apiserver-advertise-address=$(hostname -I | aws '{print $1}') --pod-network-cidr=10.244.0.0/16 --upload-certs",
      "sudo mkdir -p $HOME/.kube",
      "sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config",
      "sudo chown $(id -u):$(id -g) $HOME/.kube/config",
      "sudo kubeadm token create --print-join-command --certificate-key $(sudo kubeadm init phase upload-certs --upload-certs | tail -n 1) > /tmp/join_command.sh"
    ]

    connection {
      type        = "ssh"
      user        = module.control_plane.ssh_user[0]
      password    = module.control_plane.ssh_user[0]
      private_key = tls_private_key.ed25519-tls-private-key.private_key_openssh
      host        = module.control_plane.ssh_host[0]
    }
  }

  provisioner "local-exec" {
    command = "sshpass -p ${module.control_plane.ssh_user[0]} scp -o StrictHostKeyChecking=no ${module.control_plane.ssh_user[0]}@${module.control_plane.ssh_host[0]}:/tmp/join_command.sh ./join_command.sh"
  }

}

## KUBEADM JOIN
resource "null_resource" "kubeadm_join_control_plane" {

  depends_on = [module.control_plane, null_resource.kubeadm_init]

  count = var.config.vm_count_control_plane > 0 ? var.config.vm_count_control_plane - 1 : 0

  provisioner "file" {
    source      = "./join_command.sh"
    destination = "/tmp/join_command.sh"

    connection {
      type     = "ssh"
      user     = module.control_plane.ssh_user[count.index + 1]
      password = module.control_plane.ssh_user[count.index + 1]
      host     = module.control_plane.ssh_host[count.index + 1]
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo $(cat /tmp/join_command.sh)"
    ]

    connection {
      type     = "ssh"
      user     = module.control_plane.ssh_user[count.index + 1]
      password = module.control_plane.ssh_user[count.index + 1]
      host     = module.control_plane.ssh_host[count.index + 1]
    }
  }

}
