terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.30.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.14.0"
    }
    github = {
      source  = "integrations/github"
      version = "6.2.1"
    }
    flux = {
      source  = "fluxcd/flux"
      version = "1.3.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.5"
    }
    sops = {
      source  = "carlpett/sops"
      version = "1.0.0"
    }
    doppler = {
      source  = "DopplerHQ/doppler"
      version = "1.7.1"
    }
    proxmox = {
      source  = "telmate/proxmox"
      version = "2.9.14"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.5.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "4.34.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.4.2"
    }
  }
}

# Doppler (modules: common)
provider "doppler" {
  doppler_token = var.doppler_gbl_token
  alias         = "gbl"
}

provider "doppler" {
  doppler_token = var.doppler_env_token
  alias         = "env"
}

# Proxmox (modules: vms)
provider "proxmox" {
  pm_api_url      = var.pm_api_url
  pm_tls_insecure = true
  pm_user         = var.pm_user
  pm_password     = var.pm_password
}

# Talos (modules: k8s)
provider "talos" {}

# kubernetes (modules: flux)
provider "kubernetes" {
  host                   = yamldecode(local.kubeconfig)["clusters"][0]["cluster"]["server"]
  cluster_ca_certificate = base64decode(yamldecode(local.kubeconfig)["clusters"][0]["cluster"]["certificate-authority-data"])
  client_certificate     = base64decode(yamldecode(local.kubeconfig)["users"][0]["user"]["client-certificate-data"])
  client_key             = base64decode(yamldecode(local.kubeconfig)["users"][0]["user"]["client-key-data"])
}

provider "kubectl" {
  host                   = yamldecode(local.kubeconfig)["clusters"][0]["cluster"]["server"]
  cluster_ca_certificate = base64decode(yamldecode(local.kubeconfig)["clusters"][0]["cluster"]["certificate-authority-data"])
  client_certificate     = base64decode(yamldecode(local.kubeconfig)["users"][0]["user"]["client-certificate-data"])
  client_key             = base64decode(yamldecode(local.kubeconfig)["users"][0]["user"]["client-key-data"])
  load_config_file       = false
}

# Flux (modules: flux)
provider "flux" {
  kubernetes = {
    host                   = yamldecode(local.kubeconfig)["clusters"][0]["cluster"]["server"]
    cluster_ca_certificate = base64decode(yamldecode(local.kubeconfig)["clusters"][0]["cluster"]["certificate-authority-data"])
    client_certificate     = base64decode(yamldecode(local.kubeconfig)["users"][0]["user"]["client-certificate-data"])
    client_key             = base64decode(yamldecode(local.kubeconfig)["users"][0]["user"]["client-key-data"])
  }
  git = {
    url = "ssh://git@github.com/${var.gh_owner}/${var.repository_name}.git"
    ssh = {
      username    = "git"
      private_key = tls_private_key.flux.private_key_pem
    }
  }
}

# GitHub (modules: flux)
provider "github" {
  owner = var.gh_owner
  token = var.gh_token
}

# Cloudflare (modules: cloudflare)
provider "cloudflare" {
  email   = var.cf_email
  api_key = var.cf_apikey
}
