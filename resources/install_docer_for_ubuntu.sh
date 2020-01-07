#!/bin/sh

set -e

# Older versions of Docker were called docker, docker.io, or docker-engine. If these are installed, uninstall them:
apt-get remove docker docker-engine docker.io containerd runc

# Update the apt package index
apt-get update

# Install packages to allow apt to use a repository over HTTPS:
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common

# Add Docker’s official GPG key:
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

# Use the following command to set up the stable repository. 
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

# Update the apt package index.
apt-get update

# Install the latest version of Docker Engine - Community and containerd
apt-get install -y docker-ce docker-ce-cli containerd.io

# config docker-ce
mkdir -p /etc/docker
mkdir -p /mnt/docker_data

tee /etc/docker/daemon.json <<-'EOF'
{
    "data-root" : "/mnt/docker_data",
    "registry-mirrors" : ["https://zgvtbml8.mirror.aliyuncs.com"]
}
EOF
systemctl daemon-reload
systemctl restart docker

# Install Compose
curl -L "https://github.com/docker/compose/releases/download/1.25.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
