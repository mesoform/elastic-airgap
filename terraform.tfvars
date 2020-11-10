name = "elastic-stack"

path_to_credentials = "~/.ssh/mesoform-testing.json"
service_account_email = "mesotest@mesoform-testing.iam.gserviceaccount.com"
public_key_path = "~/.ssh/id_rsa.pub"
private_key_path = "~/.ssh/id_rsa"
project_id = "mesoform-testing"
bucket_path = "gs://mesotest/centos"

compute_region = "europe-west2"
instance_zone = "europe-west2-b"
volume_device_name = "/dev/sdf"
elasticsearch_machine_type = "e2-medium"
kibana_machine_type = "e2-medium"
logstash_machine_type = "e2-medium"

whatismyip = "147.161.85.186/32"
secure_source_ip = "0.0.0.0/0"

topic_name = "topic-mesoform-testing"
subscription_name = "subscription-mesoform-testing"
