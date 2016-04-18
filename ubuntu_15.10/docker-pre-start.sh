# see also https://github.com/tianon/cgroupfs-mount/blob/master/cgroupfs-mount
if grep -v '^#' /etc/fstab | grep -q cgroup \
        || [ ! -e /proc/cgroups ] \
        || [ ! -d /sys/fs/cgroup ]; then
        exit 0
fi
if ! mountpoint -q /sys/fs/cgroup; then
        mount -t tmpfs -o uid=0,gid=0,mode=0755 cgroup /sys/fs/cgroup
fi
(
        cd /sys/fs/cgroup
        for sys in $(awk '!/^#/ { if ($4 == 1) print $1 }' /proc/cgroups); do
                mkdir -p $sys
                if ! mountpoint -q $sys; then
                        if ! mount -n -t cgroup -o $sys cgroup $sys; then
                                rmdir $sys || true
                        fi
                fi
        done
)

# modify these in /etc/default/$UPSTART_JOB (/etc/default/docker)
DOCKER=/usr/bin/docker
DOCKER_OPTS=
if [ -f /etc/default/docker ]; then
        . /etc/default/docker
fi

if [ -f /var/run/flannel/subnet.env ]; then
## if flannel subnet env is present, then use it to define
## the subnet and MTU values
        . /var/run/flannel/subnet.env
        DOCKER_OPTS="$DOCKER_OPTS --bip=${FLANNEL_SUBNET} --mtu=${FLANNEL_MTU}"

else
        echo "Flannel subnet not found, exiting..."
        exit 1
fi

#exec "$DOCKER" daemon $DOCKER_OPTS