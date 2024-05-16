# These are placeholders for variables passed in from Doppler and Variable Sets in TF Cloud.

variable "gh_token" {
  type = string
}

variable "gh_owner" {
  type = string
}

variable "repository_name" {
  type        = string
  default     = "CloudHub-Cluster-Temp"
  description = "github repository name"
}

variable "flux_bootstrap_path" {
  type = string
  description = "The location in the git directory to store Flux bootstrap data."
}

variable "sops_age_agekey" {
  type = string
  description = "The secret agekey for the environment"
  sensitive   = true
}

variable "pm_host" {
  type = string
}

variable "pm_user" {
  type = string
}

variable "pm_password" {
  type = string
  sensitive = true
}

variable "pm_api_url" {
  type = string
  sensitive = true
}

variable "doppler_gbl_token" {
  type = string
  sensitive = true
}

variable "doppler_env_token" {
  type = string
  sensitive = true
}

# variable "kubeconfig" {}

variable "cf_email" {
  type = string
}

variable "cf_apikey" {
  type = string
  sensitive = true
}
