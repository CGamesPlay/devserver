#!/bin/bash
set -eu

ufw allow ssh
ufw allow 51820/udp
ufw allow from 10.254.0.0/24
ufw --force enable

# This is a necessary compatibility layer between docker and ufw. It also
# provides some extra commands that are required to expose the services.
# https://github.com/chaifeng/ufw-docker
wget -O /usr/local/bin/ufw-docker https://github.com/chaifeng/ufw-docker/raw/master/ufw-docker
chmod +x /usr/local/bin/ufw-docker
ufw-docker install
ufw reload
