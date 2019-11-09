#!/bin/bash
## Creates a new droplet from an existing snapshot.

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
else
  echo "Removing old SSH host key"
  ssh-keygen -R $DROPLET_NAME.$DOMAIN_NAME

  SNAPSHOT_ID=$(doctl compute snapshot list devserver --format "CreatedAt,ID" --no-header | sort -r | awk 'NR == 1 { print $2 }')
  echo "Creating droplet"
  doctl compute droplet create devserver --image $SNAPSHOT_ID $DROPLET_CONFIG --wait
  DROPLET_ID=$(doctl compute droplet list $DROPLET_NAME --format "ID" --no-header)
fi

DROPLET_ADDR=$(doctl compute droplet get $DROPLET_ID --format "PublicIPv4" --no-header)

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
