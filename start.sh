#!/bin/bash
## Spins up a devserver and configure it.

set -eu

usage() {
  sed -ne "/^##/{s/^## *//"$'\n'"p"$'\n'"}" $0
}

if [ "$#" -gt 0 ]; then
  usage >&2
  exit 1
fi

cd "$(dirname "$(python -c "import os; print(os.path.realpath('$0'))")")"

echo "Creating infrastructure"
pulumi config set devserver:running true
pulumi up --yes

INSTANCE_ADDR=$(pulumi stack output -j | jq -r .ip)
DOMAIN_NAME=$(pulumi stack output -j | jq -r .domain)

echo "Removing old SSH host key"
ssh-keygen -R $DOMAIN_NAME

echo "Adding to /etc/hosts"
cat /etc/hosts | awk '$2 != "'$DOMAIN_NAME'" { print $0 }' | sudo tee /etc/hosts~ >/dev/null
echo $INSTANCE_ADDR $DOMAIN_NAME | sudo tee -a /etc/hosts~ >/dev/null
sudo mv /etc/hosts~ /etc/hosts

echo "Waiting for cloud-init to finish"
sleep 30 # Takes some time to become reachable, cloud-init takes about 2 minutes anyways.
ssh $DOMAIN_NAME -l ubuntu -o ControlPath=none -o StrictHostKeyChecking=no -- "cloud-init status -w"
