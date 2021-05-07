terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 3.50"
    }
    bitbucket = {
      source  = "terraform-providers/bitbucket"
      version = ">= 1.2"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}
