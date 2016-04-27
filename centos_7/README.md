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
    hostone.vm.box = "centos/7"
    hostone.vm.network "private_network", ip: "192.168.33.10"
    hostone.vm.hostname = "host-one"
  end

  config.vm.define "host2" do |hosttwo|
    hosttwo.vm.box = "centos/7"
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
cd multinode_docker/centos_7/
sudo chmod 777 setup.sh
```

5) Installing docker on centos 7

complete instructions : [centos]

```
$ sudo tee /etc/yum.repos.d/docker.repo <<-'EOF'
[dockerrepo]
name=Docker Repository
baseurl=https://yum.dockerproject.org/repo/main/centos/$releasever/
enabled=1
gpgcheck=1
gpgkey=https://yum.dockerproject.org/gpg
EOF

yum update
yum install -y docker-engine
```

6) configure master
```
[terminal-1 (host1)] $ ./setup.sh master
```

7) configure node

first change the ```NODE_IP``` in ```setup.sh```. Then run the following:

```
[terminal-2 (host2)] $ ./setup.sh slave
```

[centos]: https://docs.docker.com/engine/installation/linux/centos
[docker-overlay-network-using-flannel]: http://blog.shippable.com/docker-overlay-network-using-flannel
