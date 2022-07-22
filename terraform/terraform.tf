terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "3.0.0"
    }

    google = {
      source  = "hashicorp/google"
      version = "~> 3.83.0"
    }
  }

  required_version = ">= 1.1"
}