terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.6.3"
    }
  }
}

locals {
  ssh_pri_key   = "~/.ssh/id_rsa"
}


provider "libvirt" {
  uri = "qemu:///system"
}

# Names of created virtuals
variable "vm_names" {
  description = "The names of the VMs to create"
  type = list(string)
  default = ["master1","worker1","worker2","worker3","worker4"]
}

variable "vm_network_name" {
  description = "Defines the network name"
  default = "vm_network"
}

resource "local_file" "ansiblecfg" {
    content     = <<-EOT
      [defaults]
      inventory           = ./inventory
      log_path            = ./ansible.log
      gathering           = smart
      collections_paths   = ./collections

      [inventory]
      enable_plugins = ini

      [privilege_escalation]
      become=True
      become_method=sudo
      become_user=root
    EOT
    filename    = "ansible.cfg"
    file_permission = "0664"
}

resource "local_file" "inventory" {
    content     = <<-EOT
      [kube] 
    EOT
    filename    = "${path.module}/inventory/hosts"
    file_permission = "0664"
}

resource "local_file" "group_vars" {
    content     = <<-EOT
      ---
      # Common variables
      ansible_python_interpreter: /usr/bin/python3
      ansible_user: joro
    EOT
    filename    = "${path.module}/inventory/group_vars/all"
    file_permission = "0664"
}

# Fetch image
resource "libvirt_volume" "debian" {
  name   = "${var.vm_names[count.index]}.qcow2"
  count = length(var.vm_names)
  pool   = "default"
  source = "https://laotzu.ftp.acc.umu.se/cdimage/openstack/current/debian-10.6.2-20201124-openstack-amd64.qcow2"
  format = "qcow2"
}


data "template_file" "user_data" {
  template = file("${path.module}/cloud_init.cfg")

  vars = {
    HOSTNAME = var.vm_names[count.index]
  }

  count = length(var.vm_names)
}

# Use CloudInit to users and their SSH public keys to the VM instance
resource "libvirt_cloudinit_disk" "commoninit" {
  name = "commoninit${count.index}.iso"
  user_data      = data.template_file.user_data[count.index].rendered

  count = length(var.vm_names)
}

resource "libvirt_network" "vm_network" {
  name = "vm_network"
  addresses = ["10.0.1.0/24"]
  dhcp {
    enabled = true
  }
  dns {
    enabled = true
  }
}

# Define KVM domain to create
resource "libvirt_domain" "k8s" {
  name   = var.vm_names[count.index] 
  memory = "4096"
  vcpu   = 2 
  autostart = true 

  network_interface {
    network_id = libvirt_network.vm_network.id
    network_name = var.vm_network_name
    hostname = var.vm_names[count.index]
    wait_for_lease = true
  }

  disk {
    volume_id = element(libvirt_volume.debian.*.id,count.index) 
  }

  cloudinit = libvirt_cloudinit_disk.commoninit[count.index].id

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }

# *** UPDATE ANSIBLE HOST FILE  ***
  provisioner "local-exec" {
    command = "ssh-keyscan -H ${self.network_interface.0.addresses.0} >> ~/.ssh/known_hosts; echo '${var.vm_names[count.index]} ansible_host=${self.network_interface.0.addresses.0} ansible_port=22' >> ./inventory/hosts"
  }

# *** SSH LOGIN TO REMOTE ***
    connection {
      type        = "ssh"
      user        = "joro"
      private_key = file(local.ssh_pri_key) 
      host        = self.network_interface.0.addresses.0
      port        = 22
    }

# *** PUT YOUR LOCAL ACTIONS HERE ***
    provisioner "remote-exec" {
      inline = [
        "touch huuhaa.txt",
        "touch foofoo.txt"
       ]
    }

  count = length(var.vm_names)

} # *** k8s ***

# Output Server IP
output "ip" {
  value = libvirt_domain.k8s.*.network_interface.0.addresses 
}

output "disk_id" {
  value = libvirt_volume.debian.*.id
}

output "network_id" {
  value = libvirt_network.vm_network.*.id
}

