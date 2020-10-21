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

variable "default_region" {}

variable "compute_region" {
  default = "europe-west2"
  description = "Default gcp region to manage resources in"
}

variable "instance_zone" {
  default = "europe-west2-b"
  description = "The zone of the instance. E.g. europe-west2-b"
}

variable "image" {
  default = "ubuntu-1604-xenial-v20190430"
  description = "The image to initialise the disk for instance. E.g. ubuntu-1604-xenial-v20190430"
}

//variable "gcp_vpc_cidr" {
//  description = "CIDR for subnet"
//  default     = "10.128.0.0/9"
//}
//
//variable "gcp_external_ip_name" {
//  default = "gcp-zabbix-vpn-ip"
//  description = "The GCP VPN External IP address name"
//}

variable "volume_device_name" {}

variable "ssh_user" {}

variable "public_key_path" {}

variable "private_key_path" {}

variable "local_public_ip" {}

variable "secure_source_ip" {}

variable "expiration_policy" {}

variable "topic_name" {}

variable "subscription_name" {}
