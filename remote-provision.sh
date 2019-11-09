#!/bin/bash
## Usage: provision.sh HOSTNAME
##
## Run on a blank VPS to set up docker and wireguard.
##
## The script will create an "ubuntu" user and move the configured SSH keys to
## that user, and give it passwordless sudo access. In the home directory,
## wg0.conf will be a client configuration to connect to the instance with
## Wireguard.
##
## Once connected with wireguard, you can use DOCKER_HOST=tcp://10.254.0.1 to
## access docker.

usage() {
  sed -ne "/^##/{s/^## *//"$'\n'"p"$'\n'"}" $0
}

if [ "$#" != 1 ]; then
  usage >&2
  exit 1
fi
if [ "$1" = "--help" ]; then
  usage >&2
  exit
fi

HOSTNAME="$1"

set -ex

LSB_RELEASE="Ubuntu 18.04.3 LTS"
if [ "$(lsb_release -ds)" != "$LSB_RELEASE" ]; then
  echo "Warning: designed for $LSB_RELEASE" >&2
fi

ufw allow ssh
yes | ufw enable
apt update

adduser ubuntu --disabled-password --gecos ""
usermod -aG sudo ubuntu
sed -e 's/^%sudo.*$/%sudo ALL=(ALL:ALL) NOPASSWD:ALL/' -i /etc/sudoers
mkdir /home/ubuntu/.ssh
chmod 700 /home/ubuntu/.ssh
chown ubuntu:ubuntu /home/ubuntu/.ssh
cp /root/.ssh/authorized_keys /home/ubuntu/.ssh/authorized_keys
chown ubuntu:ubuntu /home/ubuntu/.ssh/authorized_keys

add-apt-repository ppa:wireguard/wireguard
apt install -y wireguard
WG_SERVER_PRIVKEY=$(wg genkey)
WG_CLIENT_PRIVKEY=$(wg genkey)
cat >/etc/wireguard/wg0.conf <<EOF
[Interface]
PrivateKey = $WG_SERVER_PRIVKEY
Address = 10.254.0.1/32
ListenPort = 51820
SaveConfig = true

[Peer]
PublicKey = $(echo $WG_CLIENT_PRIVKEY | wg pubkey)
AllowedIPs = 10.254.0.2/32
EOF
chmod 700 /etc/wireguard/wg0.conf
ufw allow 51820/udp
wg-quick up wg0
systemctl enable wg-quick@wg0

cat >/home/ubuntu/wg0.conf <<EOF
[Interface]
PrivateKey = $WG_CLIENT_PRIVKEY
Address = 10.254.0.2/32

[Peer]
PublicKey = $(echo $WG_SERVER_PRIVKEY | wg pubkey)
AllowedIPs = 10.254.0.1/32
Endpoint = $HOSTNAME:51820
EOF
chown ubuntu:ubuntu /home/ubuntu/wg0.conf

apt install -y docker.io docker-compose
usermod -aG docker ubuntu
mkdir -p /etc/systemd/system/docker.service.d
cat >/etc/systemd/system/docker.service.d/override.conf <<EOF
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd -H fd:// -H tcp://10.254.0.1:2375
EOF
systemctl daemon-reload
systemctl start docker
systemctl enable docker
