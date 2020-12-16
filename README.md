# Elastic stack air-gapped installation on Google Cloud Platform

This repository contains the scripts and configurations to run an offline deployment of Elastic stack. 

## Quick start guide

### Deployment prerequisites

1) Elastic services (elasticsearch + logstash + kibana) `rpm` packages.

   Elastic RPM packages can be downloaded by running the `elk-airgap-download.py` script included in the `assets` folder or from the following pages:

   - https://www.elastic.co/downloads/elasticsearch
   - https://www.elastic.co/downloads/logstash
   - https://www.elastic.co/downloads/kibana
 
2) Logstash also requires 2 plugins (logstash-input-google_pubsub + logstash-filter-mutate) to ship Pub/Sub messages to logstash.
   
   Use the packaged file (`logstash-7.9.3-offline-plugins.zip`) with the plugins in the `assets` folder OR
    prepare one following these steps:

   - Make sure you have a Logstash server running 
   - Install the packages on the existing Logstash server: `bin/logtash-plugin install logstash-input-google_pubsub logstash-filter-mutate`
   - Package the plugins to be used on systems that don't have internet access: 
     `bin/logstash-plugin prepare-offline-pack --output offline-plugins.zip --overwrite logstash-input-google_pubsub logstash-filter-mutate`

3) The Java Runtime Environment `rpm` package can be downloaded from the following page: 

   - https://www.java.com/en/download/
   
Then push all those files to a GCS Storage bucket:

   E.g:
   
    server@centos:~/elastic-airgap$ gsutil ls gs://mesotest/centos
    gs://mesotest/centos/
    gs://mesotest/centos/elasticsearch-7.9.3-x86_64.rpm       # elasticsearch package
    gs://mesotest/centos/kibana-7.9.3-x86_64.rpm              # kibana package
    gs://mesotest/centos/logstash-7.9.3.rpm                   # logstash package
    gs://mesotest/centos/logstash-7.9.3-offline-plugins.zip   # logstash plugins
    gs://mesotest/centos/jre-8u271-linux-x64.tar.gz           # java runtime environment
    
### Deployment

Clone the `elastic-airgap` github repository and modify the variables file `terraform.tfvars` with the appropriate values:

   E.g:
    
    project_id = "mesoform-testing                                       # project id
    service_account_email = "mesoform@mesoform.iam.gserviceaccount.com"  # service account email
    public_key_path = "~/.ssh/id_rsa.pub"                                # auth public rsa key
    bucket_path = "gs://mesotest/centos"                                 # gcs bucket where offline elastic+java packages are stored

    network_prefix = "elastic-stack"                                     # networking resources prefix (net/subnet/firewall)
    compute_region = "europe-west2"                                      # region to create resources
    instance_zone = "europe-west2-b"                                     # zone to create compute instances
    elasticsearch_machine_type = "e2-medium"                             # Elasticsearch instance machine type
    kibana_machine_type = "e2-medium"                                    # Kibana instance machine type
    logstash_machine_type = "e2-medium"                                  # Logstash instance machine type

    secure_source_ip = "123.45.678.90/32"                                # any secure ip to access http and ssh on resources. e.g: your public IP address

    topic_name = "topic-mesoform-testing"                                # existing topic to export logging to logstash
    subscription_name = "subscription-mesoform-testing"                  # existing subscription to export logging to logstash
    
    elastic_pwd = "e1l2a3s4t5i6c"                                        # password for built-in elastic users (kibana_system/elastic)

- Authenticate to GCP. The user account needs the following IAM roles on the project: "Compute Admin" / "Compute Instance Admin (v1)" / "Storage Admin"
  and role "Service Account User" on the service account.
   
   `gcloud auth application-default login --no-launch-browser`

- To deploy resources initialise terraform and apply the changes:

   `$ cd elastic-airgap/`
   
   `$ terraform12.28 init`
   
   `$ terraform12.28 apply`

#### Access Kibana UI
    
   Get Kibana public IP either from the Terraform output, from the Compute menu on the GCP console or by running the following command: `$ gcloud compute instances list`
   
   Kibana UI can be accessed on a browser using the public Kibana server IP on port 5601 using `elastic` user and password.
   
   Note: Kibana UI could take a few minutes to be up and running.

#### Visualise logging data on Kibana
    
  1) On the home menu: Go to Visualize and Explore Data > `Dashboard` > Index patterns `+ Create index pattern`
    
  2) Define index pattern using `pubsub-*` which should the first word from the source index.
    
  3) Select a primary time field for use with the global time filter: `@timestamp` and then create the index pattern.
    
  4) Go back to the main menu and click on Visualize and Explore Data `Discover` to explore the data.
  
#### Elastic security

  1) On the home menu: Go to `Manage and Administer the Elastic Stack` > `Security Settings` > Kibana `Advance Settings`
  
  2) Scroll down to `Security Solution` settings and on Elasticsearch indices update default `securitySolution:defaultIndex` by adding `pubsub-*` to the list. That way Elastic Security app will use that index pattern to collect data.
  
  3) Go back to the main menu and click on Visualize and Explore Data `Security` to explore the data under the events tab.
  
  Documentantion: https://www.elastic.co/guide/en/security/current/advanced-settings.html
