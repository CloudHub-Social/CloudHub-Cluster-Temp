variable "gh_token" {}

variable "gh_owner" {}

variable "repository_name" {
  type        = string
  default     = "CloudHub-Cluster-Temp"
  description = "github repository name"
}

variable "flux_bootstrap_path" {
  description = "The location in the git directory to store Flux bootstrap data."
}

variable "sops_age_agekey" {
  description = "The secret agekey for the environment"
  sensitive   = true
}

variable "pm_host" {}

variable "pm_user" {}

variable "pm_password" {}

variable "pm_api_url" {}

variable "doppler_gbl_token" {}

variable "doppler_env_token" {}

# variable "kubeconfig" {}

variable "cf_email" {}

variable "cf_apikey" {}