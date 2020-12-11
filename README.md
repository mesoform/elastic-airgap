# Elastic stack air-gapped installation on Google Cloud Platform

This repository contains the scripts and configurations to run an offline deployment of Elastic stack. 

## Quick start guide

### Deployment prerequisites

1) Elastic services (elasticsearch + logstash + kibana) `rpm` packages.

   Elastic RPM packages can be downloaded by running the `elk-airgap-download.py` script included in the `assets` folder or from the following pages:

   - https://www.elastic.co/downloads/elasticsearch
   - https://www.elastic.co/downloads/logstash
   - https://www.elastic.co/downloads/kibana

2) The Java Runtime Environment `rpm` package can be downloaded from the following page: 

   - https://www.java.com/en/download/
 
3) Logstash also requires 2 plugins (logstash-input-google_pubsub + logstash-filter-mutate) to ship Pub/Sub messages to logstash.
To get a package with the plugins either use the one included in the `assets` folder or prepare one following these steps:

   - Make sure you have a Logstash server running 
   - Install the packages on the existing Logstash server: `bin/logtash-plugin install logstash-input-google_pubsub logstash-filter-mutate`
   - Package the plugins to be used on systems that don't have internet access: 
     `bin/logstash-plugin prepare-offline-pack --output offline-plugins.zip --overwrite logstash-input-google_pubsub logstash-filter-mutate`

Then push all those files to a GCS Storage bucket:

   E.g:
   
    server@centos:~/elastic-airgap$ gsutil ls gs://mesotest/centos
    gs://mesotest/centos/
    gs://mesotest/centos/elasticsearch-7.9.3-x86_64.rpm
    gs://mesotest/centos/jre-8u271-linux-x64.tar.gz
    gs://mesotest/centos/kibana-7.9.3-x86_64.rpm
    gs://mesotest/centos/logstash-7.9.3-offline-plugins.zip
    gs://mesotest/centos/logstash-7.9.3.rpm

    elasticsearch:            elasticsearch-7.9.3-x86_64.rpm
    kibana:                   kibana-7.9.3-x86_64.rpm
    logstash:                 logstash-7.9.3.rpm
    java runtime environment: jre-8u271-linux-x64.tar.gz
    logstash plugins:         logstash-7.9.3-offline-plugins.zip


### Deployment

Clone the `elastic-airgap` github repository and modify the variables file `terraform.tfvars` with the appropriate values:

   E.g:
    
    project_id = "elastic-airgap"                                        # project id
    path_to_credentials = "~/.ssh/credentials.json"                      # service account credentials
    service_account_email = "mesoform@mesoform.iam.gserviceaccount.com"  # service account email
    public_key_path = "~/.ssh/id_rsa.pub"                                # auth public rsa key
    private_key_path = "~/.ssh/id_rsa"                                   # auth private rsa key
    bucket_path = "gs://mesotest/centos"                                 # gcs bucket where offline elastic+java packages are stored

    network_prefix = "elastic-stack"                                     # networking resources prefix (net/subnet/fw)
    compute_region = "europe-west2"                                      # region to create resources
    instance_zone = "europe-west2-b"                                     # zone to create compute instances
    elasticsearch_machine_type = "e2-medium"                             # Elasticsearch instance machine type
    kibana_machine_type = "e2-medium"                                    # Kibana instance machine type
    logstash_machine_type = "e2-medium"                                  # Logstash instance machine type

    whatismyip = "147.161.85.186/32"                                     # local public ip to access http and ssh on resources
    secure_source_ip = "0.0.0.0/0"                                       # any secure ip to access http and ssh on resources

    topic_name = "topic-mesoform-testing"                                # existing topic to export logging to logstash
    subscription_name = "subscription-mesoform-testing"                  # existing subscription to export logging to logstash
    
    elastic_pwd = "e1l2a3s4t5i6c"                                        # password for built-in elastic users (kibana_system/elastic)

- To deploy resources initialise terraform and apply the changes:

   `$ cd elastic-airgap/`
   
   `$ terraform12.28 init`
   
   `$ terraform12.28 apply`

- Access Kibana UI:
    
   Get Kibana public IP either from the Compute menu on the GCP console or by running the following command locally: `$ gcloud compute instances list`
   
   Kibana UI can be accessed on a browser using the public Kibana server IP on port 5601 using `elastic` user and password
