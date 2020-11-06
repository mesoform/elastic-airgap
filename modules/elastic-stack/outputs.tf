output "service_priv_ip" {
  value = "${google_compute_instance.elastic_stack.network_interface.0.network_ip}"
}

output "service_public_ip" {
  value = "${google_compute_instance.elastic_stack.network_interface.0.access_config.0.nat_ip}"
}
