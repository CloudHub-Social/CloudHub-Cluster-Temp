variable "flux_bootstrap_path" {
  type        = string
  description = "The location in the git directory to store Flux bootstrap data."
}

variable "sops_age_agekey" {
  type        = string
  description = "The secret agekey for the environment"
  sensitive   = true
}

variable "repository_name" {
  type        = string
  default     = "CloudHub-Cluster-Temp"
  description = "github repository name"
}

variable "tls_private_key" {
  type = string
}

variable "doppler-env" {
  type = map
}
