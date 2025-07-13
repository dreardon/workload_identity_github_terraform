resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "google_storage_bucket" "scc-iac-staged-bucket" {
  name          = "example-${random_string.bucket_suffix.result}"
  location      = "US"
  force_destroy = true
  project = var.PROJECT_ID
}