data "google_project" "project" {
}

output "project_number" {
  value = data.google_project.project.number
}

resource "google_storage_bucket" "example-bucket" {
  name          = "${var.PROJECT_ID}-example"
  location      = "US"
  force_destroy = true
  uniform_bucket_level_access = true
  project = var.PROJECT_ID
}