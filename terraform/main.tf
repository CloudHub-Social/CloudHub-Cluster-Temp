terraform {
  cloud {
    organization = "jaxcb7e5133"
    workspaces {
      tags = ["cloudhub"]
    }
  }
}

data "doppler_secrets" "gbl" {
  provider = doppler.gbl
}

data "doppler_secrets" "env" {
  provider = doppler.env
}

module "common" {
  source = "./modules/common"
}

module "vms" {
  source     = "./modules/vms"
  depends_on = [module.common]
  pm_host    = var.pm_host
}

output "controlplane_nodes" {
  value = module.vms.controlplane_nodes
}

output "worker_nodes" {
  value = module.vms.worker_nodes
}

module "k8s" {
  source = "./modules/k8s"
  depends_on = [
    module.vms
  ]
  providers = {
    doppler = doppler.env
  }
  controlplane_nodes = module.vms.controlplane_nodes
  worker_nodes       = module.vms.worker_nodes
}

output "vip_ip" {
  value = module.k8s.vip_ip
}

locals {
  kubeconfig  = module.k8s.kubeconfig
  talosconfig = module.k8s.talosconfig
  depends_on = [
    module.k8s
  ]
}

output "kubeconfig" {
  value     = module.k8s.kubeconfig
  sensitive = true
}

output "talosconfig" {
  value     = module.k8s.talosconfig
  sensitive = true
}

resource "tls_private_key" "flux" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

module "flux" {
  source = "./modules/flux"
  depends_on = [
    module.vms,
    module.k8s,
    local.kubeconfig,
    local.talosconfig,
    time_sleep.wait_for_kubernetes_up
  ]
  providers = {
    kubernetes = kubernetes,
    kubectl    = kubectl,
    github     = github,
    flux       = flux
  }
  flux_bootstrap_path = var.flux_bootstrap_path
  sops_age_agekey     = var.sops_age_agekey
  tls_private_key     = tls_private_key.flux
  doppler-env         = data.doppler_secrets.env
}

module "cloudflare" {
  source = "./modules/cloudflare"
  providers = {
    doppler    = doppler.env
    cloudflare = cloudflare
  }
}
