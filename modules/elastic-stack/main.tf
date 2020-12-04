data "template_file" "install_elastic_stack" {
  template = "${file("modules/elastic-stack/files/install_elasticstack.sh.tpl")}"

  vars = {
    hostname              = var.hostname
    volume_device_name    = var.volume_device_name
    volume_mount_path     = var.volume_mount_path
    bucket_path           = var.bucket_path
    elasticsearch_priv_ip = var.elasticsearch_priv_ip
    project_id            = var.project_id
    topic_name            = var.topic_name
    subscription_name     = var.subscription_name
    elastic_pwd           = var.elastic_pwd
  }
}

resource "google_compute_instance" "elastic_stack" {
  name          = var.hostname
  machine_type  = var.machine_type
  zone          = var.instance_zone
  project       = var.project_id

  tags          = ["${var.hostname}"]

  boot_disk {
    initialize_params {
      image = var.image
    }
  }

  attached_disk {
    source = element(concat(google_compute_disk.elastic_volume.*.self_link, list("")), 0)
  }

  network_interface {
    network = var.compute_network_name

    subnetwork = var.compute_subnetwork_name

    access_config {
      // Ephemeral IP
    }
  }

  service_account {
    email = var.service_account_email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.public_key_path)}"
  }

  provisioner "file" {
    source = var.path_to_credentials
    destination = "~/.ssh/mesoform-testing.json"

    connection {
      type = "ssh"
      user = "centos"
      private_key = file("${var.private_key_path}")
      host = self.network_interface.0.access_config.0.nat_ip
    }
  }

  metadata_startup_script = data.template_file.install_elastic_stack.rendered
}

resource "google_compute_disk" "elastic_volume" {
  name    = "${var.hostname}-volume"
  project = var.project_id

  count   = var.disk_type == "" ? 0 : 1
  type    = var.disk_type
  zone    = var.instance_zone
  size    = var.disk_size
}
