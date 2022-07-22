
resource "google_service_account" "dataproc-service-account" {
  account_id   = "dataproc-service-account"
  display_name = "Dataproc Default Service Account"
}

resource "google_storage_bucket" "dataproc_staging_bucket" {
  name          = "dataproc-cluster-0"
  location      = "eu"
  uniform_bucket_level_access = true
}

resource "google_project_iam_binding" "dataproc_worker" {
  role    = "roles/dataproc.worker"
  members = [
    "serviceAccount:${google_service_account.dataproc-service-account.email}"
  ]
}

resource "google_storage_bucket" "dataproc_config" {
  name          = "dataproc-cluster-0-config"
  location      = "eu"
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_object" "init_script" {
  name     = var.init_script
  source   = "${path.module}/${var.init_script}"
  bucket   = google_storage_bucket.dataproc_config.name
}

resource "google_dataproc_cluster" "dataproc-cluster" {
  count = 1
  name     = "dataproc-cluster-${count.index}-${random_id.instance_id.hex}"
  region   = var.region
  labels = {
    environment = "prod"
  }

  cluster_config {
    staging_bucket = google_storage_bucket.dataproc_staging_bucket.name

    master_config {
      num_instances = var.count_server["master"]
      machine_type  = var.machine_types["master"]
      disk_config {
        boot_disk_type    = var.disk_type["master"]
        boot_disk_size_gb = var.disk_size["master"]
      }
      image_uri = "projects/${var.project}/global/images/custom-debian10-java11"
    }

    worker_config {
      num_instances    = var.count_server["worker"]
      machine_type     = var.machine_types["worker"]
      disk_config {
        boot_disk_type    = var.disk_type["worker"]
        boot_disk_size_gb = var.disk_size["worker"]
      }
      image_uri = "projects/${var.project}/global/images/custom-debian10-java11"
    }

    preemptible_worker_config {
      num_instances = var.count_server["preemptible"]
    }

    software_config {
      image_version = var.image_version
      override_properties = {
        "dataproc:dataproc.allow.zero.workers" = "true"
        "spark-env:JAVA_HOME" = "/usr/lib/jvm/java-11-openjdk-amd64"
        "spark:spark.executorEnv.JAVA_HOME" = "/usr/lib/jvm/java-11-openjdk-amd64"
      }
    }

    gce_cluster_config {
      tags = ["prod", "spark"]
      service_account_scopes = [
        "monitoring",
        "useraccounts-ro",
        "storage-rw",
        "logging-write"
      ]
      service_account = google_service_account.dataproc-service-account.email
      subnetwork = google_compute_subnetwork.dataproc_subnetwork.name
      internal_ip_only = true
    }

    initialization_action {
      script = "gs://${google_storage_bucket_object.init_script.bucket}/${google_storage_bucket_object.init_script.name}"
      timeout_sec = 500
    }

  }

  timeouts {
    create = "1h"
    update = "1h"
    delete = "20m"
  }
}
