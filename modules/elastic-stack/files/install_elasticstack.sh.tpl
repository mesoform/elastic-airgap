#!/bin/bash
#
# Elastic Stack Offline Installation Script
#

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

install_elastic_service() {
  local elastic_service="$1"
  echo "Installing $elastic_service"
  cd /tmp
  gsutil cp ${bucket_path}/$elastic_service* /tmp
  package_file=$(ls $elastic_service* | grep rpm$ --max-count=1)
  sudo rpm --install package_file
  sudo systemctl daemon-reload
  sudo systemctl enable $elastic_service.service
  sudo systemctl start $elastic_service.service
}

main() {
  if [[ $EUID != 0 ]]; then
    echo "This script must be run as root"
    exit 1
  fi

  install_java && echo

  case ${hostname} in
  elasticsearch)
    install_elastic_service ${hostname} && echo
    ;;
  logstash)
    echo "logstash"
    ;;
  kibana)
    install_elastic_service ${hostname} && echo
    ;;
  *)
    echo ${hostname} "is not an Elastic stack service" && exit 1
    ;;
  esac
}

main | tee /tmp/install_elasticstack_$(date +%Y%m%d-%H%M).log
