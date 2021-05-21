variable "google_project_services" {
  type        = list(string)
  description = "Google Project Services to be enabled"
  default = [
    "run.googleapis.com",
    "containerregistry.googleapis.com",
    "sqladmin.googleapis.com",
    "logging.googleapis.com"
  ]
}

variable "gcp_region" {
  type        = string
  description = "Google Cloud Region"
  default     = "us-central1"
}

variable "pipelines_ip_addresses" {
  type        = list(string)
  description = "My IP addresses for remote connections to SQL instances upon deployment"
  default = [
    "104.197.141.53/32"
  ]
}

