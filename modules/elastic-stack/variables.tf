variable "hostname" {
  description = "Elastic service"
}

variable "volume_device_name" {
  default     = "/dev/sdb"
  description = "The device name. E.g. /dev/sdf"
}

variable "volume_mount_path" {
  default     = "/var"
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

variable "ssh_user" {
  default = "centos"
}

variable "public_key_path" {}

variable "disk_type" {
  default = "pd-ssd"
  description = "The GCE disk type. One of pd-standard or pd-ssd"
}

variable "disk_size" {
  default = "20"
  description = "The size of the image in gigabytes"
}

variable "bucket_path" {}

variable "elasticsearch_priv_ip" {
  default="0.0.0.0"
}

variable "topic_name" {
  default="test-topic"
}

variable "subscription_name" {
  default="test-subscription"
}

variable "elastic_pwd" {}
