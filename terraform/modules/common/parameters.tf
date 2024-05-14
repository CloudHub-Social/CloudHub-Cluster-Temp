locals {
  env = {
    default = {
      # VMS
      cores       = 4
      sockets     = 1
      memory      = 4096
      disk_0_size = "50G"
      disk_1_size = "25G"
      net_bridge  = "vmbr7"
      wr_count    = 3
      # K8S
      cluster_name     = "cloudhub-dev"
      cluster_endpoint = "https://10.0.42.10:6443"
      vip_ip           = "10.0.42.10"
      logging_ip       = "10.0.42.60"
    }
    dev = {
      # VMS
      cores       = 4
      sockets     = 1
      memory      = 4096
      disk_0_size = "50G"
      disk_1_size = "25G"
      net_bridge  = "vmbr7"
      wr_count    = 3
      # K8S
      cluster_name     = "cloudhub-dev"
      cluster_endpoint = "https://10.0.42.10:6443"
      vip_ip           = "10.0.42.10"
      logging_ip       = "10.0.42.60"
    }
    stg = {
      # VMS
      cores       = 4
      sockets     = 1
      memory      = 4096
      disk_0_size = "50G"
      disk_1_size = "25G"
      net_bridge  = "vmbr8"
      wr_count    = 3
      # K8S
      cluster_name     = "cloudhub-stg"
      cluster_endpoint = "https://10.0.43.10:6443"
      vip_ip           = "10.0.43.10"
      logging_ip       = "10.0.43.60"
    }
    prod = {
      # VMS
      cores       = 8
      sockets     = 2
      memory      = 16384
      disk_0_size = "50G"
      disk_1_size = "25G"
      net_bridge  = "vmbr6"
      wr_count    = 3
      # K8S
      cluster_name     = "cloudhub-prod"
      cluster_endpoint = "https://10.0.41.10:6443"
      vip_ip           = "10.0.41.10"
      logging_ip       = "10.0.41.60"

    }
  }
  environmentvars = contains(keys(local.env), terraform.workspace) ? terraform.workspace : "default"
  workspace       = merge(local.env["default"], local.env[local.environmentvars])
}
