#!/bin/bash
echo "Enter your Real-Debrid api key"
read api
export DEBIAN_FRONTEND=noninteractive
export DEBIAN_PRIORITY=critical
sudo -E apt-get -qy update
sudo -E apt-get -qy -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" upgrade
sudo sed -i 's/#$nrconf{restart} = '\''i'\'';/$nrconf{restart} = '\''a'\'';/' /etc/needrestart/needrestart.conf
sudo -E apt-get -qy autoclean
sudo rm -rf /usr/local/go

sudo apt install libfuse-dev git wget docker.io -y

wget https://go.dev/dl/go1.19.9.linux-arm64.tar.gz
tar -xvf go1.19.9.linux-arm64.tar.gz
sudo mv go /usr/local

# Write the new PATH environment variable to ~/.bashrc
cat <<EOT >> ~/.bashrc
export PATH=\$PATH:/usr/local/go/bin
export GOPATH=\$HOME/go
export PATH=\$PATH:\$GOPATH/bin
EOT

# Source ~/.bashrc to update the current shell's environment variables
source ~/.bashrc