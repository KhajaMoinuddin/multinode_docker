#!/bin/bash

# see also https://github.com/jainvipin/kubernetes-ubuntu-start
ETCD=/opt/bin/etcd
if [ -f /etc/default/etcd ]; then
        . /etc/default/etcd
fi
if [ -f $ETCD ]; then
        exit 0
fi
echo "$ETCD binary not found, exiting"
exit 22

# modify these in /etc/default/etcd (/etc/default/etcd)
ETCD=/opt/bin/etcd
ETCD_OPTS=""
if [ -f /etc/default/etcd ]; then
        . /etc/default/etcd
fi
#exec "$ETCD" $ETCD_OPTS