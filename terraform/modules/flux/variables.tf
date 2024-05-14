variable "flux_bootstrap_path" {
  description = "The location in the git directory to store Flux bootstrap data."
}

variable "sops_age_agekey" {
  description = "The secret agekey for the environment"
  sensitive   = true
}

variable "repository_name" {
  type        = string
  default     = "CloudHub-Cluster-Temp"
  description = "github repository name"
}

variable "tls_private_key" {}
