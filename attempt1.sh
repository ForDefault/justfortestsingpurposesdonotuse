#!/bin/bash
echo "Enter your Real-Debrid api key"
read api
export DEBIAN_FRONTEND=noninteractive
export DEBIAN_PRIORITY=critical
sudo -E apt-get -qy update
sudo -E apt-get -qy -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" upgrade
sudo sed -i 's/#$nrconf{restart} = '\''i'\'';/$nrconf{restart} = '\''a'\'';/' /etc/needrestart/needrestart.conf
sudo -E apt-get -qy autoclean
sudo apt install golang libfuse-dev git wget docker.io -y
sudo git clone https://github.com/itsToggle/rclone_RD
cd /home/ubuntu/rclone_RD
sudo systemctl enable docker
# Build the rclone binary.
sudo go build -tags cmount

# Check if the build was successful.
if [ $? -ne 0 ]; then
    echo "Failed to build rclone binary."
    exit 1
fi

# Move the rclone binary.
sudo mv /home/ubuntu/rclone_RD/rclone /sbin/mount.rclone

# Check if the move was successful.
if [ ! -f /sbin/mount.rclone ]; then
    echo "Failed to move rclone binary."
    exit 1
fi
mkdir /home/ubuntu/.config
mkdir /home/ubuntu/.config/rclone
sudo printf "[rd]\ntype = realdebrid\napi_key = "$api >> /home/ubuntu/.config/rclone/rclone.conf
# Create the mount point.
mkdir -p /home/ubuntu/rclone_mnt

# Add the mount to /etc/fstab.
sudo su -c "echo 'rd: /home/ubuntu/rclone_mnt rclone config=/home/ubuntu/.config/rclone/rclone.conf,dir_cache_time=10s,buffer_size=4G,allow-other 0 0' >> /etc/fstab"

# Get the ID of the plugin.
plugin_id=$(sudo docker plugin ls --no-trunc --format "{{.ID}}" | head -n 1)

# Enable the plugin.
sudo docker plugin enable $plugin_id

# Check if the plugin is enabled.
enabled=$(sudo docker plugin ls --no-trunc --format "{{.ID}}:{{.Enabled}}" | grep "^$plugin_id:true")

if [ -z "$enabled" ]; then
    echo "Failed to enable Docker plugin $plugin_id."
    exit 1
fi

# Mount the filesystem.
sudo mount -a

# Check if the mount was successful.
if ! mountpoint -q /home/ubuntu/rclone_mnt; then
    echo "Failed to mount /home/ubuntu/rclone_mnt."
    exit 1
fi

# Create the Docker network.
sudo docker network create docker
sudo docker run -d --name=plex --network=host -v /home/ubuntu/plex_config:/config -v /home/ubuntu/rclone_mnt:/library --restart always lscr.io/linuxserver/plex
sleep 5
echo "Enter your Plex claim: plex.tv/claim"
read claim
sudo docker exec -ti plex curl -X POST 'http://localhost:32400/myplex/claim?token='$claim
touch /home/ubuntu/settings.json
sudo docker pull itstoggle/plex_debrid:latest
sudo docker run -d -ti --name=plex_debrid --network=host -v /home/ubuntu/settings.json:/config/settings.json --restart always itstoggle/plex_debrid
sudo iptables -I INPUT -p tcp --dport 32400 -j ACCEPT
sudo sh -c "iptables-save > /etc/iptables/rules.v4"
sudo sh -c "ip6tables-save > /etc/iptables/rules.v6"
cd ~
echo "-----"
echo "-----"
echo "-----"
echo "-----"
echo "-----"
echo "Installation complete"
echo "Refer to https://mediawiki.godver3.xyz/index.php/Oracle_Quick-Start_Guide for more information"
