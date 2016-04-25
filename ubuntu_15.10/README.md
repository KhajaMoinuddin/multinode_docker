# multi-node docker
based on : [docker-overlay-network-using-flannel]

## setup
1) create vagrantfile
```
 # -*- mode: ruby -*-

# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  config.vm.define "host1" do |hostone|
    hostone.vm.box = "trusty64"
    hostone.vm.network "private_network", ip: "192.168.33.10"
    hostone.vm.hostname = "host-one"
  end

  config.vm.define "host2" do |hosttwo|
    hosttwo.vm.box = "trusty64"
    hosttwo.vm.network "private_network", ip: "192.168.33.11"
    hosttwo.vm.hostname = "host-two"
  end

end
```

2) bring up master
```
[terminal-1] $ vagrant up host1
[terminal-1] $ vagrant ssh host1
```

3) bring up node
```
[terminal-2] $ vagrant up host2
[terminal-2] $ vagrant ssh host2
```

4) download service files and setup script
```
git clone https://github.com/stephenranjit/multinode_docker.git
cd ubuntu_15.10/
sudo cp etcd.service /etc/systemd/system/
sudo cp flanneld.service /etc/systemd/system/
sudo cp docker.service /etc/systemd/system/
sudo chmod 777 setup.sh
```

5) configure master
```
[terminal-1 (host1)] $ ./setup.sh master
```

6) configure node
```
[terminal-2 (host2)] $ ./setup.sh slave
```

# docker
complete instructions : [ubuntu]
## Installing docker on ubuntu 15.10

```
apt-get update
apt-get install apt-transport-https ca-certificates

apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070
touch /etc/apt/sources.list.d/docker.list
echo 'deb https://apt.dockerproject.org/repo ubuntu-wily main' > /etc/apt/sources.list.d/docker.list
apt-get update
apt-get purge lxc-docker
apt-cache policy docker-engine
apt-get install --force-yes -y linux-image-extra-$(uname -r)

apt-get install --force-yes -y apparmor
apt-get install --force-yes -y docker-engine

sed -i.bak s/GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX='"cgroup_enable=memory swapaccount=1"'/g /etc/default/grub
sudo update-grub
```

[ubuntu]: https://docs.docker.com/engine/installation/linux/ubuntulinux/
[docker-overlay-network-using-flannel]: http://blog.shippable.com/docker-overlay-network-using-flannel
