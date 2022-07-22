variable "project" {
  type = string
}

variable "init_script" {
  default = "data/init.sh"
}

variable "staging_bucket" {
  type = string
  default = "dataproc-cluster-0"
}

variable "location" {
  type = string
  default = "us"
}

variable "region" {
  type = string
  default = "us-central1"
}

variable "zone" {
  type = string
  default = "us-central1-a"
}

variable "cidrs" { default = [ "10.0.0.0/16", "10.1.0.0/16" ] }

variable "environment" {
  type = string
  default = "master"
}

variable "machine_types" {
  type = map(string)
  default = {
    "worker" = "n1-standard-2"
    "master" = "n1-standard-2"
    "preemptible" = "n1-standard-2"
  }
}

variable "disk_type" {
  type = map(string)
  default = {
    "worker" = "pd-standard"
    "master" = "pd-standard"
    "preemptible" = "pd-standard"
  }
}

variable "image_version" {
   type = string
   default = "2.0.49-debian10"
}

variable "disk_size" {
  type = map(string)
  default = {
    "worker" = 30
    "master" = 30
  }
}

variable "count_server" {
  type = map(string)
  default = {
    "worker" = 2
    "master" = 1
    "preemptible" = 0
  }
}

variable "sql_tier" {
  type = string
  default = "db-n1-standard-2"
}
