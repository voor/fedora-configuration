#!/usr/bin/env bash

sudo tee /etc/yum.repos.d/docker.repo <<-'EOF'
[dockerrepo]
name=Docker Repository
baseurl=https://yum.dockerproject.org/repo/main/fedora/$releasever/
enabled=1
gpgcheck=1
gpgkey=https://yum.dockerproject.org/gpg
EOF

# More recent version will replace the one distributed with Fedora.
sudo dnf install -y docker-engine
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker `whoami`
sudo dnf install -y docker-compose
