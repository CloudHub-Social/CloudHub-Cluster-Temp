terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    kubectl = {
      source = "gavinbunney/kubectl"
    }
    github = {
      source = "integrations/github"
    }
    tls = {
      source = "hashicorp/tls"
    }
    flux = {
      source = "fluxcd/flux"
    }
    doppler = {
      source = "DopplerHQ/doppler"
    }
  }
}

module "common" {
  source = "../common"
}

data "doppler_secrets" "env" {
  provider = doppler
}

locals {
  doppler-env = {
    map = data.doppler_secrets.env.map
  }
}

# Kubernetes Namespace
resource "kubernetes_namespace" "flux_system" {
  metadata {
    name = "flux-system"
  }

  lifecycle {
    ignore_changes = [
      metadata[0].labels,
    ]
  }
}

resource "github_repository_deploy_key" "this" {
  title      = "Flux (${terraform.workspace})"
  repository = var.repository_name
  key        = var.tls_private_key.public_key_openssh
  read_only  = "false"
}

resource "flux_bootstrap_git" "this" {
  depends_on = [github_repository_deploy_key.this]

  # path = var.flux_bootstrap_path
  path = local.doppler-env.map.FLUX_BOOTSTRAP_PATH
}

resource "kubernetes_secret" "sops-age" {
  metadata {
    name      = "sops-age"
    namespace = "flux-system"
  }
  type = "generic"
  data = {
    # "age.agekey" = var.sops_age_agekey
    "age.agekey" = local.doppler-env.map.SOPS_AGE_AGEKEY
  }
}
