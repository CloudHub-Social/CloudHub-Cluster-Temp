terraform {
  required_providers {
    proxmox = {
      source = "telmate/proxmox"
    }
  }
}

module "common" {
  source = "../common"
}

variable "pm_host" {
  type = string
}

# resource is formatted to be "[type]" "[entity_name]" so in this case
# we are looking to create a proxmox_vm_qemu entity named test_server
resource "proxmox_vm_qemu" "talos-control-plane" {
  count = 3
  name  = "talos-control-${terraform.workspace}-${count.index + 1}" #count.index starts at 0, so + 1 means this VM will be named test-vm-1 in proxmox
  # this now reaches out to the vars file. I could've also used this var above in the pm_api_url setting but wanted to spell it out up there. target_node is different than api_url. target_node is which node hosts the template and thus also which node will host the new VM. it can be different than the host you use to communicate with the API. the variable contains the contents "prox-1u"
  target_node = var.pm_host
  # another variable with contents "ubuntu-2004-cloudinit-template"
  iso = "local:iso/metal-amd64.iso"
  # basic VM settings here. agent refers to guest agent
  agent   = 1
  cores   = module.common.workspace["cores"]
  sockets = module.common.workspace["sockets"]
  cpu     = "host"
  memory  = module.common.workspace["memory"]
  scsihw  = "virtio-scsi-pci"
  qemu_os = "other"

  pool = "CloudHub-${upper(terraform.workspace)}"
  tags = lower(terraform.workspace)

  onboot = true

  disk {
    slot    = 0
    size    = module.common.workspace["disk_0_size"]
    type    = "scsi"
    storage = "local-lvm"
    discard = "on"
    ssd     = 1
    backup  = true
  }

  disk {
    slot    = 1
    size    = module.common.workspace["disk_1_size"]
    type    = "scsi"
    storage = "local-lvm"
    discard = "on"
    ssd     = 1
    backup  = true
  }

  # if you want two NICs, just copy this whole network section and duplicate it
  network {
    model  = "virtio"
    bridge = module.common.workspace["net_bridge"]
  }
  # not sure exactly what this is for. presumably something about MAC addresses and ignore network changes during the life of the VM
  lifecycle {
    ignore_changes = [
      network,
      disk,
    ]
  }

  define_connection_info = true

  timeouts {
    create = "10m"
    delete = "10m"
  }

}

resource "proxmox_vm_qemu" "talos-worker" {
  count = module.common.workspace["wr_count"]
  name  = "talos-worker-${terraform.workspace}-${count.index + 1}" #count.index starts at 0, so + 1 means this VM will be named test-vm-1 in proxmox
  # this now reaches out to the vars file. I could've also used this var above in the pm_api_url setting but wanted to spell it out up there. target_node is different than api_url. target_node is which node hosts the template and thus also which node will host the new VM. it can be different than the host you use to communicate with the API. the variable contains the contents "prox-1u"
  target_node = var.pm_host
  # another variable with contents "ubuntu-2004-cloudinit-template"
  iso = "local:iso/metal-amd64.iso"
  # basic VM settings here. agent refers to guest agent
  agent   = 1
  cores   = module.common.workspace["cores"]
  sockets = module.common.workspace["sockets"]
  cpu     = "host"
  memory  = module.common.workspace["memory"]
  scsihw  = "virtio-scsi-pci"
  qemu_os = "other"

  pool = "CloudHub-${upper(terraform.workspace)}"
  tags = lower(terraform.workspace)

  onboot = true

  disk {
    slot    = 0
    size    = module.common.workspace["disk_0_size"]
    type    = "scsi"
    storage = "local-lvm"
    discard = "on"
    ssd     = 1
    backup  = true
  }

  disk {
    slot    = 1
    size    = module.common.workspace["disk_1_size"]
    type    = "scsi"
    storage = "local-lvm"
    discard = "on"
    ssd     = 1
    backup  = true
  }

  # if you want two NICs, just copy this whole network section and duplicate it
  network {
    model  = "virtio"
    bridge = module.common.workspace["net_bridge"]
  }
  # not sure exactly what this is for. presumably something about MAC addresses and ignore network changes during the life of the VM
  lifecycle {
    ignore_changes = [
      network,
      disk,
    ]
  }

  define_connection_info = true

  timeouts {
    create = "10m"
    delete = "10m"
  }

}

output "controlplane_nodes" {
  value = [
    {
      node_id  = proxmox_vm_qemu.talos-control-plane.*.id,
      hostname = proxmox_vm_qemu.talos-control-plane.*.name,
      ip       = proxmox_vm_qemu.talos-control-plane.*.default_ipv4_address
    }
  ]
  depends_on = [proxmox_vm_qemu.talos-control-plane]
}

output "worker_nodes" {
  value = [
    {
      node_id  = proxmox_vm_qemu.talos-worker.*.id,
      hostname = proxmox_vm_qemu.talos-worker.*.name,
      ip       = proxmox_vm_qemu.talos-worker.*.default_ipv4_address
    }
  ]
  depends_on = [proxmox_vm_qemu.talos-worker]
}
