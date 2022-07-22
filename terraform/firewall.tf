resource "google_compute_firewall" "allow_ssh" {
 name    = "dataproc-ssh-firewall"
 network = google_compute_network.dataproc_network.id

 allow {
   protocol = "tcp"
   ports    = ["22"]
 }

 source_ranges = ["0.0.0.0/0"]
}

# allow all access from health check ranges
resource "google_compute_firewall" "dataproc-vpc-allow-internal" {
  project = var.project
  name          = "dataproc-vpc-allow-internal"
  provider      = google-beta
  direction     = "INGRESS"
  network       = google_compute_network.dataproc_network.id
  source_ranges = [var.cidrs[0]]
  allow {
    protocol = "tcp"
    ports = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports = ["0-65535"]
  }
  allow {
    protocol = "icmp"
  }
 }

