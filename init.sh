#!/bin/bash
## Create a new VPS and prepares it to be a remote docker host.

set -e

usage() {
  sed -ne "/^##/{s/^## *//"$'\n'"p"$'\n'"}" $0
}

if [ "$#" -gt 0 ]; then
  usage >&2
  exit 1
fi

cd "$(dirname "$(python -c "import os; print(os.path.realpath('$0'))")")"
. .env

DROPLET_ID=$(doctl compute droplet list $DROPLET_NAME --format "ID" --no-header)
if [ ! -z "$DROPLET_ID" ]; then
  echo "A droplet named $DROPLET_NAME is already running" >&2
  exit 1
fi

echo "Creating a new droplet"
doctl compute droplet create $DROPLET_NAME --image ubuntu-18-04-x64 $DROPLET_CONFIG --wait
echo "Waiting for machine to boot"
sleep 30
DROPLET_ID=$(doctl compute droplet list $DROPLET_NAME --format "ID" --no-header)
DROPLET_ADDR=$(doctl compute droplet get $DROPLET_ID --format "PublicIPv4" --no-header)
echo "Running provisioning script"
cat remote-provision.sh | ssh -o StrictHostKeyChecking=no root@$DROPLET_ADDR -- bash /dev/stdin $DROPLET_NAME.$DOMAIN_NAME
echo "Saving wg0.conf locally"
ssh -o StrictHostKeyChecking=no ubuntu@$DROPLET_ADDR -- cat wg0.conf >wg0.conf

echo "Adding to DNS ($DROPLET_NAME.$DOMAIN_NAME -> $DROPLET_ADDR)"
RECORD_ID=$(doctl compute domain records list $DOMAIN_NAME --format "Name,ID" | awk '$1 == "'$DROPLET_NAME'" { print $2 }')
if [ ! -z "$RECORD_ID" ]; then
  doctl compute domain records delete $DOMAIN_NAME $RECORD_ID -f
fi
doctl compute domain records create $DOMAIN_NAME --record-name $DROPLET_NAME --record-type A --record-data $DROPLET_ADDR

echo "Adding to /etc/hosts"
cat /etc/hosts | awk '$2 != "'$DROPLET_NAME.$DOMAIN_NAME'" { print $0 }' | sudo tee /etc/hosts~ >/dev/null
echo $DROPLET_ADDR $DROPLET_NAME.$DOMAIN_NAME | sudo tee -a /etc/hosts~ >/dev/null
sudo mv /etc/hosts~ /etc/hosts
