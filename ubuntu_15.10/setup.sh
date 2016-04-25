#!/bin/bash -e
#
# Copyright 2015 Shippable Inc. All rights reserved.
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
export FLANNEL_VERSION=0.5.5
export FLANNEL_EXECUTABLE_LOCATION=/usr/bin
export ETCD_VERSION=v2.3.1
export ETCD_EXECUTABLE_LOCATION=/usr/bin
export ETCD_PORT=4001

install_prereqs() {
  sudo apt-get install -yy bridge-utils
}

install_etcd() {
  ## download, extract and update etcd binaries ##
  echo 'Installing etcd on master...'
  cd $DOWNLOAD_PATH;
  sudo rm -r etcd-$ETCD_VERSION-linux-amd54 || true;
  etcd_download_url="https://github.com/coreos/etcd/releases/download/$ETCD_VERSION/etcd-$ETCD_VERSION-linux-amd64.tar.gz";
  sudo curl -L $etcd_download_url -o etcd.tar.gz;
  sudo tar xzvf etcd.tar.gz && cd etcd-$ETCD_VERSION-linux-amd64;
  sudo mv -v etcd $ETCD_EXECUTABLE_LOCATION/etcd;
  sudo mv -v etcdctl $ETCD_EXECUTABLE_LOCATION/etcdctl;
  echo `which etcd`
  echo 'Etcd installed correctly'
}

update_etcd_config() {
  echo "ETCD=$ETCD_EXECUTABLE_LOCATION/etcd" | sudo tee -a  /etc/default/etcd
  echo "ETCD_OPTS='-advertise-client-urls=http://localhost:$ETCD_PORT -listen-client-urls=http://0.0.0.0:$ETCD_PORT'" | sudo tee -a /etc/default/etcd
  echo "etcd config updated successfully"
}

download_flannel_release() {
  ## download and extract flannel archive ##
  echo "Downloading flannel release version: $FLANNEL_VERSION"

  cd $DOWNLOAD_PATH
  flannel_download_url="https://github.com/coreos/flannel/releases/download/v$FLANNEL_VERSION/flannel-$FLANNEL_VERSION-linux-amd64.tar.gz";
  sudo curl -L $flannel_download_url -o flannel.tar.gz;
  sudo tar xzvf flannel.tar.gz && cd flannel-$FLANNEL_VERSION;
  sudo mv -v flanneld $FLANNEL_EXECUTABLE_LOCATION/flanneld
}

update_flanneld_config() {
  echo "FLANNELD_OPTS='-etcd-endpoints=http://$MASTER_IP:$ETCD_PORT -iface=$NODE_IP'" | sudo tee -a /etc/default/flanneld
}

start_etcd() {
  sudo service etcd restart || true
  sleep 5
}

update_flanneld_subnet() {
  ## update the key in etcd which determines the subnet that flannel uses
  $ETCD_EXECUTABLE_LOCATION/etcdctl --peers=http://$MASTER_IP:$ETCD_PORT set coreos.com/network/config '{"Network":"'"$FLANNEL_SUBNET"'"}'
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
download_flannel_release

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
