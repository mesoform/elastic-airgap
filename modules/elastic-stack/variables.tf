variable "hostname" {
  description = "Elastic service"
}

variable "volume_device_name" {
  description = "The device name. E.g. /dev/sdf"
}

variable "volume_mount_path" {
  default     = "/mnt/elastic"
  description = "The volume mount path"
}

variable "machine_type" {
  default = "e2-medium"
  description = "The machine type to create"
}

variable "instance_zone" {
  description = "The zone of the instance. E.g. us-east1-b"
}

variable "project_id" {}

variable "service_account_email" {
  description = "Service account client email"
}

variable "image" {
  description = "The image to initialise the disk for instance. E.g. ubuntu-1604-xenial-v20190430"
}

variable "compute_region" {
  description = "Default gcp region to manage resources in"
//  default = "us-east1"
}

variable "compute_network_name" {
  description = "The name of the network attached to interface in this instance"
}

variable "compute_subnetwork_name" {
  description = "The name of the subnetwork attached to interface in this instance"
}

variable "ssh_user" {}

variable "public_key_path" {}

variable "private_key_path" {}

variable "path_to_credentials" {}

variable "disk_type" {
  default = "pd-ssd"
  description = "The GCE disk type. One of pd-standard or pd-ssd"
}

variable "disk_size" {
  default = "20"
  description = "The size of the image in gigabytes"
}

variable "bucket_path" {}

variable "elasticsearch_public_ip" {
  default="localhost"
}
