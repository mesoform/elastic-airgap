data "template_file" "install_elastic_stack" {
  template = "${file("${path.module}/files/install_elasticstack.sh.tpl")}"

  vars {
    hostname              = "${var.hostname}"

    volume_device_name    = "${var.volume_device_name}"
    volume_mount_path     = "${var.volume_mount_path}"
    elasticsearch_image   = "${var.elasticsearch_image}"

    project               = "${var.project_id}"
    mcp_topic_name        = "${var.topic_name}"
    mcp_subscription_name = "${var.subscription_name}"

  }
}

resource "google_compute_instance" "elastic_stack" {
  name          = "${var.hostname}"
  machine_type  = "${var.machine_type}"
  zone          = "${var.instance_zone}"
  project       = "${var.project_id}"

  tags          = ["${var.hostname}"]

  boot_disk {
    initialize_params {
      image = "${var.image}"
    }
  }
//  gcp_public_key_path
  attached_disk {
    source = "${element(concat(google_compute_disk.elastic_volume.*.self_link, list("")), 0)}"
  }

  network_interface {
    network = "${var.compute_network_name}"

    subnetwork = "${var.compute_subnetwork_name}"

    access_config {
      // Ephemeral IP
    }
  }

  service_account {
    email = "${var.service_account_email}"
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  metadata {
    ssh-keys = "${var.ssh_user}:${file(var.public_key_path)}"
  }

  provisioner "file" {
    source = "${var.path_to_credentials}"
    destination = "~/.ssh/mcp-service.json"
  }

  connection {
    type = "ssh"
    user = "ubuntu"
    private_key = "${file("${var.gcp_private_key_path}")}"
    agent = "false"
  }

  metadata_startup_script = "${data.template_file.install_elastic_stack.rendered}"
}

resource "google_compute_disk" "elastic_volume" {
  name    = "${var.hostname}-volume"
  project = "${var.project_id}"

  count   = "${var.disk_type == "" ? 0 : 1}"
  type    = "${var.disk_type}"
  zone    = "${var.instance_zone}"
  size    = "${var.disk_size}"
}
