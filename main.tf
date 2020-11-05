/* Setup google provider */
provider "google" {
  credentials = file("${var.path_to_credentials}")
  project     = var.project_id
  region      = var.compute_region
}

# Network
resource "google_compute_network" "elastic_net" {
  name                    = "${var.name}-network"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "elastic_subnet" {
  name          = "${var.name}-subnetwork651"
  ip_cidr_range = "10.65.1.0/24"
  region        = var.compute_region
  network       = google_compute_network.elastic_net.self_link
}

resource "google_compute_firewall" "elastic_firewall" {
  name          = "${var.name}-ports"
  network       = google_compute_network.elastic_net.name
//  source_tags = ["${var.name}-servers"]
  source_ranges = ["${google_compute_subnetwork.elastic_subnet.ip_cidr_range}"]

  allow {
    protocol = "tcp"

    ports = [
      "22",          # SSH
      "80",          # HTTP
      "443",         # HTTPS
      "5044",        # Elastic Stack: Logstash Beats interface
      "5601",        # Elastic Stack: Kibana web interface
      "9200",        # Elastic Stack: Elasticsearch JSON interface
      "9300",        # Elastic Stack: Elasticsearch transport interface
      "9600",        # Elastic Stack: Logstash
    ]
  }
}

resource "google_compute_firewall" "elastic_fw_ext" {
  name          = "${var.name}-ext-ports"
  network       = google_compute_network.elastic_net.name
//  source_tags = ["${var.name}-servers"]
  source_ranges = ["${var.local_public_ip}", "${var.secure_source_ip}"]

  allow {
    protocol = "tcp"

    ports = [
      "22",          # SSH
      "80",          # HTTP
      "443",         # HTTPS
      "5601"         # Elastic Stack: Kibana web interface
    ]
  }
}

#module "export_logging" {
#  source = "./modules/export-logging"
#
#  project_id = var.project_id
#  expiration_policy = var.expiration_policy
#}

module "elasticsearch" {
  source = "./modules/elastic-stack"

  hostname                = "elasticsearch"
  project_id              = var.project_id
  service_account_email   = var.service_account_email
  compute_region          = var.compute_region
  instance_zone           = var.instance_zone
  compute_network_name    = google_compute_network.elastic_net.name
  compute_subnetwork_name = google_compute_subnetwork.elastic_subnet.name
  image                   = var.image
  volume_device_name      = var.volume_device_name
  ssh_user                = var.ssh_user
  public_key_path         = var.public_key_path
  private_key_path        = var.private_key_path
  path_to_credentials     = var.path_to_credentials
  bucket_path             = var.bucket_path
}

module "kibana" {
  source = "./modules/elastic-stack"

  hostname                = "kibana"
  project_id              = var.project_id
  service_account_email   = var.service_account_email
  compute_region          = var.compute_region
  instance_zone           = var.instance_zone
  compute_network_name    = google_compute_network.elastic_net.name
  compute_subnetwork_name = google_compute_subnetwork.elastic_subnet.name
  image                   = var.image
  volume_device_name      = var.volume_device_name
  ssh_user                = var.ssh_user
  public_key_path         = var.public_key_path
  private_key_path        = var.private_key_path
  path_to_credentials     = var.path_to_credentials
  bucket_path             = var.bucket_path
  elasticsearch_priv_ip   = module.elasticsearch.service_priv_ip
}

module "logstash" {
  source = "./modules/elastic-stack"

  hostname                = "logstash"
  project_id              = var.project_id
  service_account_email   = var.service_account_email
  compute_region          = var.compute_region
  instance_zone           = var.instance_zone
  compute_network_name    = google_compute_network.elastic_net.name
  compute_subnetwork_name = google_compute_subnetwork.elastic_subnet.name
  image                   = var.image
  volume_device_name      = var.volume_device_name
  ssh_user                = var.ssh_user
  public_key_path         = var.public_key_path
  private_key_path        = var.private_key_path
  path_to_credentials     = var.path_to_credentials
  bucket_path             = var.bucket_path
  elasticsearch_priv_ip   = module.elasticsearch.service_priv_ip
  topic_name              = var.topic_name
  subscription_name       = var.subscription_name
#  topic_name              = module.export_logging.topic_name
#  subscription_name       = module.export_logging.subscription_name
}
