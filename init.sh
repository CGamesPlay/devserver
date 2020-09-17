#!/bin/bash
## Create a new VPS and prepares it to be a remote docker host.

set -eu
set -o pipefail

usage() {
  sed -ne "/^##/{s/^## *//"$'\n'"p"$'\n'"}" $0
}

if [ "$#" -gt 0 ]; then
  usage >&2
  exit 1
fi

cd "$(dirname "$(python -c "import os; print(os.path.realpath('$0'))")")"
unset PULUMI_HOME

pulumi stack init dev
echo "Devserver domain name:"
pulumi config set devserver:domain
echo "DigitalOcean region name:"
pulumi config set devserver:region
echo "DigitalOcean access token:"
pulumi config set digitalocean:token --secret
