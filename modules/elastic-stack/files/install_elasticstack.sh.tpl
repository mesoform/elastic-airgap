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

set_users_passwords() {
#wait for elasticsearch to be available
  while true
  do
    curl --fail -u "elastic:$BOOTSTRAP_PWD" \
      "http://$ELASTIC_SERVICE:9200/_cluster/health?wait_for_status=yellow" \
      && break
    sleep 5
  done

#set passwords for various users
  for elastic_user in "kibana" "kibana_system" "logstash_system" "apm_system" "beats_system" "elastic"
  do
    elastic_user_pwd=$ELASTIC_PWD
    curl -u "elastic:$BOOTSTRAP_PWD" \
      -XPOST "http://$ELASTIC_SERVICE:9200/_xpack/security/user/$elastic_user/_password" \
      -d'{"password":"$elastic_user_pwd"}' -H "Content-Type: application/json"
    printf "%s=%s\n" "$elastic_user" "$elastic_user_pwd" >> /tmp/passwords.txt
  done
}

start_elastic_service() {
  sudo systemctl daemon-reload
  sudo systemctl enable $ELASTIC_SERVICE.service
  sudo systemctl start $ELASTIC_SERVICE.service
  if [ $ELASTIC_SERVICE == "elasticsearch" ]; then
    set_users_passwords
  fi
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
  config_file=/etc/$ELASTIC_SERVICE/$ELASTIC_SERVICE.yml

  case $ELASTIC_SERVICE in
  elasticsearch)
    local priv_ip=$(hostname -I)
    echo "#elastic-airgap: config $ELASTIC_SERVICE" >> $config_file
    echo "node.name: $ELASTIC_SERVICE" >> $config_file
    echo "cluster.initial_master_nodes: [\"$ELASTIC_SERVICE\"]" >> $config_file
    echo "network.host: $priv_ip" >> $config_file
    echo "discovery.seed_hosts: [\"127.0.0.1\", \"[::1]\"]" >> $config_file
    sed -i "s/path.data:.*$//g" $config_file && sudo mkdir -p $MOUNT_PATH && echo "path.data: $MOUNT_PATH" >> $config_file
    echo "xpack.security.enabled: true" >> $config_file
    echo "xpack.security.transport.ssl.enabled: true" >> $config_file
    BOOTSTRAP_PWD="$(date +%s | sha256sum | base64 | head -c 32)"
    echo "$BOOTSTRAP_PWD" > /tmp/bootstrap_pwd.log
    printf "%s" "$BOOTSTRAP_PWD" | /usr/share/elasticsearch/elasticsearch-keystore add -x "bootstrap.password"
    ;;
  logstash)
    plugins_file=$(ls $ELASTIC_SERVICE* | grep zip$ --max-count=1)
    /usr/share/logstash/bin/logstash-plugin install file://$(pwd)/$plugins_file
    generate_logstash_config
    ;;
  kibana)
    echo "#elastic-airgap: config $ELASTIC_SERVICE" >> $config_file
    echo "elasticsearch.hosts: [\"http://${elasticsearch_priv_ip}:9200\"]" >> $config_file
    echo "server.host: 0.0.0.0" >> $config_file
    echo "elasticsearch.username: \"kibana_system\"" >> $config_file
    echo "elasticsearch.password: \"$ELASTIC_PWD\"" >> $config_file
    echo "xpack.security.encryptionKey: \"$(date +%s | sha256sum | base64 | head -c 32)\"" >> $config_file
    echo "xpack.security.session.idleTimeout: \"1h\"" >> $config_file
    echo "xpack.security.session.lifespan: \"30d\"" >> $config_file
    ;;
  esac
}

install_elastic_service() {
  echo "Installing $ELASTIC_SERVICE"
  cd /tmp
  gsutil cp ${bucket_path}/$ELASTIC_SERVICE* /tmp
  package_file=$(ls $ELASTIC_SERVICE* | grep rpm$ --max-count=1)
  sudo rpm --install $package_file
}

main() {
  if [[ $EUID != 0 ]]; then
    echo "This script must be run as root"
    exit 1
  fi

  ELASTIC_SERVICE=${hostname}
  ELASTIC_PWD=${elastic_pwd}

  MOUNT_PATH=${volume_mount_path}/$ELASTIC_SERVICE

  mount_volume

  install_java && echo

  case $ELASTIC_SERVICE in
  elasticsearch | logstash | kibana)
    install_elastic_service && echo
    config_elastic_service && echo
    start_elastic_service && echo
    ;;
  *)
    echo $ELASTIC_SERVICE "is not an Elastic stack service" && exit 1
    ;;
  esac
}

main | tee /tmp/install_elasticstack_$(date +%Y%m%d-%H%M).log
