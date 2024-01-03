#!/usr/bin/env bash

set -e

cd "$(dirname "$0")"
pwd
docker pull vaultwarden/server:latest-alpine
id=$(docker create vaultwarden/server:latest-alpine)
rm -rf ./tmp
mkdir -p ./tmp
mkdir -p ./tmp/vaultwarden
docker cp "$id:/vaultwarden" ./tmp/vaultwarden/
docker cp "$id:/web-vault" ./tmp/vaultwarden/
docker rm -v "$id"

cd ./tmp/

./vaultwarden/vaultwarden --version | grep -Eo '[0-9]+.[0-9]+\.[0-9]+' >./vaultwarden/version.txt
cat >./vaultwarden/run.sh <<EOF
#!/bin/bash

vaultwarden
EOF

tar czf ../vaultwarden.tar.gz ./vaultwarden
cd ..
rm -rf ./tmp
