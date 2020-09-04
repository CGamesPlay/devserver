#!/bin/bash
set -eu

cd /mnt/data/wireguard
umask 077
genkey() {
    if [ -e $1 ]; then
        echo "$1 exists; not regenerating" >&2
    else
        wg genkey > $1
    fi
}

genkey server.key
genkey client.key

cat >/etc/wireguard/wg0.conf <<EOF
[Interface]
PrivateKey = $(cat server.key)
Address = 10.254.0.1/32
ListenPort = 51820

[Peer]
PublicKey = $(cat client.key | wg pubkey)
AllowedIPs = 10.254.0.2/32
EOF

cat >/home/ubuntu/wg0.conf <<EOF
[Interface]
PrivateKey = $(cat client.key)
Address = 10.254.0.2/32

[Peer]
PublicKey = $(cat server.key | wg pubkey)
AllowedIPs = 10.254.0.1/32
Endpoint = $(hostname -f):51820
EOF
chown ubuntu:ubuntu /home/ubuntu/wg0.conf

systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0
