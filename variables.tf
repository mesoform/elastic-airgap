variable "name" {
  description = "Human readable name used as prefix to generated names."
}

variable "path_to_credentials" {
  description = "Path to gcp service account key file"
}

variable "service_account_email" {
  description = "Service account client email"
}

variable "project_id" {}

variable "compute_region" {
  default = "europe-west2"
  description = "Default gcp region to manage resources in"
}

variable "instance_zone" {
  default = "europe-west2-b"
  description = "The zone of the instance. E.g. europe-west2-b"
}

variable "image" {
  default = "centos-7-v20201014"
  description = "The image to initialise the disk for instance."
}

variable "volume_device_name" {}

variable "public_key_path" {}

variable "private_key_path" {}

variable "whatismyip" {}

variable "secure_source_ip" {}

variable "bucket_path" {}

variable "expiration_policy" {
  default = "604800s"
}

variable "topic_name" {
  default="test-topic"
}

variable "subscription_name" {
  default="test-subscription"
}
