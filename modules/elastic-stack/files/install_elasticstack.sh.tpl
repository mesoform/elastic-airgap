#!/bin/bash
#
# Elastic Stack Offline Installation Script
#

mount_volume() {
  device_name_input=${volume_device_name}

  echo "device name: $device_name_input" >> /var/log/syslog

  if [ "$device_name_input" != '' ]; then
    sudo mkfs.ext4 -m 0 -F -E lazy_itable_init=0,lazy_journal_init=0,discard $device_name_input
    sudo mkdir -p $MOUNT_PATH
    sudo mount -o discard,defaults $device_name_input $MOUNT_PATH
    sudo chmod a+w $MOUNT_PATH
    UUID=$(sudo blkid -s UUID -o value $device_name_input)
    echo $UUID $MOUNT_PATH ext4 discard,defaults,nofail 0 2 | sudo tee -a /etc/fstab
  fi
}

install_java() {
  echo "Installing Java Runtime Environment (JRE)"
  cd /tmp
  gsutil cp ${bucket_path}/jre* /tmp
  java_file=$(ls -r jre*tar.gz | grep x64 --max-count=1 | cut -d/ -f2)
  sudo mkdir -p /usr/lib/jvm
  java_build=$(cut -d- -f1 <<< $java_file)"1."$(cut -d- -f2 <<< $java_file | sed 's/u/.0_/')
  sudo tar -C /usr/lib/jvm -zxf $java_file
  sudo update-alternatives --install "/usr/bin/java" "java" "/usr/lib/jvm/"$java_build"/bin/java" 1
  sudo update-alternatives --install "/usr/bin/javaws" "javaws" "/usr/lib/jvm/"$java_build"/bin/javaws" 1
  sudo chmod a+x /usr/bin/java
  sudo chmod a+x /usr/bin/javaws
  sudo chown -R root:root /usr/lib/jvm/$java_build
  java -version
}

start_elastic_service() {
  sudo systemctl daemon-reload
  sudo systemctl enable $elastic_service.service
  sudo systemctl start $elastic_service.service
}

generate_logstash_config() {
echo "input {
  google_pubsub {
    project_id => \"${project_id}\"
    topic => \""${topic_name}"\"
    subscription => \""${subscription_name}"\"
    include_metadata => true
    codec => \"json\"
    tags => [\"pubsub\"]
  }
}

filter {
  mutate { convert => [\"container.labels.org_label-schema_build-date\",\"string\"] }
  mutate { convert => [\"docker.container.labels.org_label-schema_build-date\",\"string\"] }
}

output {
  if \"pubsub\" in [tags] {
    elasticsearch {
      hosts    => \"${elasticsearch_priv_ip}:9200\"
      index => \"${topic_name}-%%{+yyyy.MM.dd}\"
    }
  }
}
" > /etc/logstash/conf.d/logstash.conf
}

config_elastic_service() {
  config_file=/etc/$elastic_service/$elastic_service.yml

  case $elastic_service in
  elasticsearch)
    local priv_ip=$(hostname -I)
    echo "#elastic-airgap: config $elastic_service" >> $config_file
    echo "node.name: $elastic_service" >> $config_file
    echo "cluster.initial_master_nodes: [\"$elastic_service\"]" >> $config_file
    echo "network.host: $priv_ip" >> $config_file
    echo "discovery.seed_hosts: [\"127.0.0.1\", \"[::1]\"]" >> $config_file
    sed -i "s/path.data:.*$//g" $config_file && sudo mkdir -p $MOUNT_PATH && echo "path.data: $MOUNT_PATH" >> $config_file
    ;;
  logstash)
    plugins_file=$(ls $elastic_service* | grep zip$ --max-count=1)
    /usr/share/logstash/bin/logstash-plugin install file://$(pwd)/$plugins_file
    generate_logstash_config
    ;;
  kibana)
    echo "#elastic-airgap: config $elastic_service" >> $config_file
    echo "elasticsearch.hosts: [\"http://${elasticsearch_priv_ip}:9200\"]" >> $config_file
    echo "server.host: 0.0.0.0" >> $config_file
    ;;
  esac
}

install_elastic_service() {
  echo "Installing $elastic_service"
  cd /tmp
  gsutil cp ${bucket_path}/$elastic_service* /tmp
  package_file=$(ls $elastic_service* | grep rpm$ --max-count=1)
  sudo rpm --install $package_file
}

main() {
  if [[ $EUID != 0 ]]; then
    echo "This script must be run as root"
    exit 1
  fi

  elastic_service=${hostname}

  MOUNT_PATH=${volume_mount_path}/$elastic_service

  mount_volume

  install_java && echo

  case $elastic_service in
  elasticsearch | logstash | kibana)
    install_elastic_service && echo
    config_elastic_service && echo
    start_elastic_service && echo
    ;;
  *)
    echo $elastic_service "is not an Elastic stack service" && exit 1
    ;;
  esac
}

main | tee /tmp/install_elasticstack_$(date +%Y%m%d-%H%M).log
