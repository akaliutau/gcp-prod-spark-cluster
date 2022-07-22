resource "google_compute_network" "dataproc_network" {
  name = "dataproc-vpc-network-${random_id.instance_id.hex}"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "dataproc_subnetwork" {
  name = "dataproc-vpc-subnet-1"
  ip_cidr_range = var.cidrs[0]
  network = google_compute_network.dataproc_network.name
  region = var.region
  private_ip_google_access = true
}

