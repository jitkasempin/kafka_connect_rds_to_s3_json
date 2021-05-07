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

