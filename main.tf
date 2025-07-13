resource "google_storage_bucket" "example-bucket" {
  name          = "${var.PROJECT_ID}-example"
  location      = "US"
  force_destroy = true
  project = var.PROJECT_ID
}