output "elasticsearch_external_ip" {
  value = "${module.elasticsearch.service_public_ip}"
}

output "logstash_external_ip" {
  value = "${module.logstash.service_public_ip}"
}

output "kibana_external_ip" {
  value = "${module.kibana.service_public_ip}"
}
