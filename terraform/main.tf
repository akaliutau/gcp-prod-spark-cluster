provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

resource "random_id" "instance_id" {
   byte_length = 8
}

resource "google_project_service" "compute_api" {
  project = var.project
  service = "compute.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "oslogin_api" {
  project = var.project
  service = "oslogin.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "iam_api" {
  project = var.project
  service = "iam.googleapis.com"
  disable_on_destroy = false
}
