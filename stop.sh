#!/bin/bash
## Shuts down the devserver and clean up the local system.

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

echo "Removing DNS"
RECORD_ID=$(doctl compute domain records list $DOMAIN_NAME --format "Name,ID" | awk '$1 == "'$DROPLET_NAME'" { print $2 }')
if [ ! -z "$RECORD_ID" ]; then
  doctl compute domain records delete $DOMAIN_NAME $RECORD_ID -f
fi

echo "Removing from /etc/hosts"
cat /etc/hosts | awk '$2 != "'$DROPLET_NAME.$DOMAIN_NAME'" { print $0 }' | sudo tee /etc/hosts~ >/dev/null
sudo mv /etc/hosts~ /etc/hosts

echo "Removing SSH host key"
ssh-keygen -R $DROPLET_NAME.$DOMAIN_NAME

DROPLET_ID=$(doctl compute droplet list $DROPLET_NAME --format "ID" --no-header)
if [ -z $DROPLET_ID ]; then
  echo "Machine already destroyed"
else
  echo "Shutting down machine"
  doctl compute droplet-action shutdown $DROPLET_ID --wait
  echo "Making a snapshot"
  doctl compute droplet-action snapshot $DROPLET_ID --snapshot-name $DROPLET_NAME --wait
  echo "Deleting droplet"
  doctl compute droplet delete $DROPLET_ID -f
fi

echo "Deleting old snapshots"
SNAPSHOT_IDS=$(doctl compute snapshot list devserver --format "CreatedAt,ID" --no-header | sort -r | awk 'NR > 1 { print $2 }')
if [ ! -z "$SNAPSHOT_IDS" ]; then
  doctl compute snapshot delete $SNAPSHOT_IDS -f
fi
