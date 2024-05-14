terraform {
  required_providers {
    talos = {
      source = "siderolabs/talos"
    }
    doppler = {
      source = "DopplerHQ/doppler"
    }
  }
}

module "common" {
  source = "../common"
}

resource "talos_machine_secrets" "machine_secrets" {
  talos_version = "v1.7.1"
}

variable "controlplane_nodes" {
  description = "Controlplane Nodes"
}

variable "worker_nodes" {
  description = "Worker Nodes"
}

data "talos_machine_configuration" "machineconfig_cp" {
  cluster_name     = module.common.workspace["cluster_name"]
  cluster_endpoint = module.common.workspace["cluster_endpoint"]
  machine_type     = "controlplane"
  talos_version    = talos_machine_secrets.machine_secrets.talos_version
  machine_secrets  = talos_machine_secrets.machine_secrets.machine_secrets
}

data "talos_machine_configuration" "machineconfig_worker" {
  cluster_name     = module.common.workspace["cluster_name"]
  cluster_endpoint = module.common.workspace["cluster_endpoint"]
  machine_type     = "worker"
  talos_version    = talos_machine_secrets.machine_secrets.talos_version
  machine_secrets  = talos_machine_secrets.machine_secrets.machine_secrets
}

data "talos_client_configuration" "talosconfig" {
  cluster_name         = module.common.workspace["cluster_name"]
  client_configuration = talos_machine_secrets.machine_secrets.client_configuration
  endpoints            = var.controlplane_nodes[0].ip
}

resource "talos_machine_configuration_apply" "cp_config_apply" {
  client_configuration        = talos_machine_secrets.machine_secrets.client_configuration
  machine_configuration_input = data.talos_machine_configuration.machineconfig_cp.machine_configuration

  count    = 3
  endpoint = tostring(var.controlplane_nodes[0].ip[count.index])
  node     = tostring(var.controlplane_nodes[0].ip[count.index])

  config_patches = [
    templatefile("${path.module}/templates/install-disk-and-hostname.yaml.tmpl", {
      hostname     = tostring(var.controlplane_nodes[0].hostname[count.index])
      install_disk = "/dev/sda"
    }),
    templatefile("${path.module}/templates/cp-vip.yaml.tmpl", {
      vip_ip = module.common.workspace["vip_ip"]
    }),
    templatefile("${path.module}/templates/node-config-all.yaml.tmpl", {
      logging_ip = module.common.workspace["logging_ip"]
    }),
    file("${path.module}/files/cp-scheduling.yaml"),
    file("${path.module}/files/cp-extraargs.yaml"),
    file("${path.module}/files/podsecuritypolicy.yaml"),
    file("${path.module}/files/cluster-extramanifests.yaml")
  ]
  depends_on = [var.controlplane_nodes]
}

resource "talos_machine_configuration_apply" "worker_config_apply" {
  client_configuration        = talos_machine_secrets.machine_secrets.client_configuration
  machine_configuration_input = data.talos_machine_configuration.machineconfig_worker.machine_configuration

  count    = module.common.workspace["wr_count"]
  endpoint = tostring(var.worker_nodes[0].ip[count.index])
  node     = tostring(var.worker_nodes[0].ip[count.index])

  config_patches = [
    templatefile("${path.module}/templates/install-disk-and-hostname.yaml.tmpl", {
      hostname     = tostring(var.worker_nodes[0].hostname[count.index])
      install_disk = "/dev/sda"
    }),
    templatefile("${path.module}/templates/node-config-all.yaml.tmpl", {
      logging_ip = module.common.workspace["logging_ip"]
    }),
  ]
  depends_on = [var.worker_nodes]
}

resource "talos_machine_bootstrap" "bootstrap" {
  depends_on = [
    talos_machine_configuration_apply.cp_config_apply,
    talos_machine_configuration_apply.worker_config_apply
  ]
  client_configuration = talos_machine_secrets.machine_secrets.client_configuration
  endpoint             = var.controlplane_nodes[0].ip[0]
  node                 = var.controlplane_nodes[0].ip[0]
}

data "talos_cluster_kubeconfig" "kubeconfig" {
  depends_on = [
    talos_machine_bootstrap.bootstrap
  ]
  client_configuration = talos_machine_secrets.machine_secrets.client_configuration
  endpoint             = var.controlplane_nodes[0].ip[0]
  node                 = var.controlplane_nodes[0].ip[0]
}

data "talos_cluster_health" "health" {
  client_configuration = talos_machine_secrets.machine_secrets.client_configuration
  control_plane_nodes  = var.controlplane_nodes[0].ip
  endpoints            = var.controlplane_nodes[0].ip
  worker_nodes         = var.worker_nodes[0].ip
  timeouts = {
    create = "5m"
  }
  depends_on = [
    talos_machine_bootstrap.bootstrap
  ]
}

output "vip_ip" {
  value = module.common.workspace["vip_ip"]
}

output "kubeconfig" {
  depends_on = [
    talos_machine_secrets.machine_secrets,
    talos_machine_bootstrap.bootstrap,
    data.talos_cluster_kubeconfig.kubeconfig,
    data.talos_cluster_health.health
  ]
  value = data.talos_cluster_kubeconfig.kubeconfig.kubeconfig_raw
}

output "talosconfig" {
  depends_on = [
    data.talos_client_configuration.talosconfig
  ]
  value = data.talos_client_configuration.talosconfig.talos_config
}

resource "doppler_secret" "kubeconfig" {
  project = "cloudhub"
  config  = terraform.workspace
  name    = "KUBECONFIG"
  value   = data.talos_cluster_kubeconfig.kubeconfig.kubeconfig_raw
  depends_on = [
    talos_machine_secrets.machine_secrets,
    talos_machine_bootstrap.bootstrap,
    data.talos_cluster_kubeconfig.kubeconfig,
    data.talos_cluster_health.health
  ]
}

resource "doppler_secret" "talosconfig" {
  project = "cloudhub"
  config  = terraform.workspace
  name    = "TALOSCONFIG"
  value   = data.talos_client_configuration.talosconfig.talos_config
  depends_on = [
    data.talos_client_configuration.talosconfig
  ]
}
