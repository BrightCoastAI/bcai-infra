terraform {
  required_version = ">= 1.9.0"

  backend "gcs" {
    bucket = "bc-prod-brightcoast-tfstate"
    prefix = "terraform/root"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.40"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.40"
    }
  }
}
