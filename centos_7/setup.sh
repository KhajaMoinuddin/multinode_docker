#!/bin/bash -e
#
# Copyright 2016 stephenranjit@gmail.com All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

if [[ $# > 0 ]]; then
  if [[ "$1" == "slave" ]]; then
    export INSTALLER_TYPE=slave
  else
    export INSTALLER_TYPE=master
  fi
else
  export INSTALLER_TYPE=master
fi

export NODE_IP=192.168.33.10
export MASTER_IP=192.168.33.10
export FLANNEL_SUBNET=10.100.0.0/16
export DOWNLOAD_PATH=/tmp
export ETCD_PORT=4001

install_prereqs() {
  sudo yum install -y bridge-utils
}

install_etcd() {
  echo 'Installing etcd on master...'
  sudo yum -y install etcd
  echo `which etcd`
  echo 'etcd installed correctly'
}

update_etcd_config() {
cat << EOF > /etc/etcd/etcd.conf
ETCD_NAME=default
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:$ETCD_PORT"
ETCD_ADVERTISE_CLIENT_URLS="http://localhost:$ETCD_PORT"
EOF
  echo "etcd config updated successfully"
}

install_flanneld() {
  echo "Installing flannel release version: $FLANNEL_VERSION"
  sudo yum -y install flannel
  echo `which flanneld`
  echo 'flanneld installed correctly'
}

update_flanneld_config() {

  #FLANNEL_ETCD="http://127.0.0.1:2379"
  sed -i s/FLANNEL_ETCD=.*/FLANNEL_ETCD="http:\/\/$MASTER_IP:$ETCD_PORT"/g /etc/sysconfig/flanneld
  #sed -i s/#FLANNEL_OPTIONS=.*/FLANNELD_OPTS="-etcd-endpoints=http://$MASTER_IP:$ETCD_PORT -iface=$NODE_IP"/g /etc/sysconfig/flanneld
  #echo "FLANNELD_OPTS='-etcd-endpoints=http://$MASTER_IP:$ETCD_PORT -iface=$NODE_IP'" | sudo tee -a /etc/sysconfig/flanneld
}

start_etcd() {
  sudo service etcd restart || true
  sleep 5
}

update_flanneld_subnet() {
  ## update the key in etcd which determines the subnet that flannel uses
  $ETCD_EXECUTABLE_LOCATION/etcdctl --peers=http://$MASTER_IP:$ETCD_PORT set /atomic.io/network/config '{"Network":"'"$FLANNEL_SUBNET"'"}'
}

clear_network_entities() {
  ## remove the docker0 bridge created by docker daemon
  echo "stopping docker"
  sudo service docker stop || true
  echo "removing docker0 bridge"
  sudo ip link set dev docker0 down  || true
  sudo brctl delbr docker0 || true
}

start_services() {
  ## need to restart docker to reload the config
  ## after this docker starts/stops with flanneld service
  echo 'Starting services...'
  sudo service flanneld restart || true
  sudo service docker restart || true
  is_success=true
}

before_exit() {
  if [ "$is_success" == true ]; then
    echo "Script Completed Successfully";
  else
    echo "Script executing failed";
  fi
}

trap before_exit EXIT
install_prereqs

if [[ $INSTALLER_TYPE == 'master' ]]; then
  # Only install etcd on master.
  trap before_exit EXIT
  install_etcd

  trap before_exit EXIT
  update_etcd_config
fi

trap before_exit EXIT
install_flanneld

trap before_exit EXIT
update_flanneld_config

if [[ $INSTALLER_TYPE == 'master' ]]; then
  trap before_exit EXIT
  start_etcd

  trap before_exit EXIT
  update_flanneld_subnet
fi

trap before_exit EXIT
clear_network_entities

trap before_exit EXIT
start_services
