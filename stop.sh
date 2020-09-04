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

DOMAIN_NAME=$(pulumi stack output -j | jq -r .domain)

echo "Removing from /etc/hosts"
cat /etc/hosts | awk '$2 != "'$DOMAIN_NAME'" { print $0 }' | sudo tee /etc/hosts~ >/dev/null
sudo mv /etc/hosts~ /etc/hosts

echo "Removing SSH host key"
ssh-keygen -R $DOMAIN_NAME

echo "Cleaning infrastructure"
pulumi config set devserver:running false
pulumi up --yes
