variable "project_id" {
  description = "GCP project ID"
}

variable "network_prefix" {
  description = "Human readable name used as prefix to generated names"
}

variable "subnet_cidr_range" {
  description = "The range of internal addresses that are owned by this subnetwork. For example, 10.0.0.0/8 or 192.168.0.0/16"
}

variable "service_account_email" {
  description = "Service account client email"
}

variable "public_key_path" {
  description = "Auth public rsa key"
}

variable "bucket_path" {
  description = "GCS bucket where offline elastic+java packages are stored"
}

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

variable "elasticsearch_machine_type" {
  default = "e2-medium"
}

variable "kibana_machine_type" {
  default = "e2-medium"
}

variable "logstash_machine_type" {
  default = "e2-medium"
}

variable "secure_source_ip" {
  description = "Any secure IP to access HTTP and ssh on resources"
}

variable "expiration_policy" {
  default = "604800s"
}

variable "topic_name" {
  default="test-topic"
}

variable "subscription_name" {
  default="test-subscription"
}

variable "elastic_pwd" {
  default="e1l2a3s4t5i6c"
}
