terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7.2"
    }    
    google = {
      source = "hashicorp/google"
      version = "6.43.0"
    }
  }
}

provider "google" {
  project = var.PROJECT_ID
}