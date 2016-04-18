#!/bin/bash

FLANNELD=/usr/bin/flanneld
    if [ -f /etc/default/flanneld ]; then
            . /etc/default/flanneld
    fi
    if [ -f $FLANNELD ]; then
            exit 0
    fi
echo "$FLANNELD binary not found, exiting"
exit 22

# modify these in /etc/default/flanneld
FLANNELD=/usr/bin/flanneld
FLANNELD_OPTS=""
if [ -f /etc/default/flanneld ]; then
        . /etc/default/flanneld
fi
#exec "$FLANNELD" $FLANNELD_OPTS