DOCKER_OPTS=
if [ -f /etc/default/docker]; then
        . /etc/default/docker
fi
if ! printf "%s" "$DOCKER_OPTS" | grep -qE -e '-H|--host'; then
        while ! [ -e /var/run/docker.sock ]; do
                initctl status $UPSTART_JOB | grep -q "stop/" && exit 1
                echo "Waiting for /var/run/docker.sock"
                sleep 0.1
        done
        echo "/var/run/docker.sock is up"
fi