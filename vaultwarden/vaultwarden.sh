#!/usr/bin/env bash

set -e

cd "$(dirname "$0")"
pwd
tag=1.30.1-alpine
docker pull vaultwarden/server:$tag
id=$(docker create vaultwarden/server:$tag)
rm -rf ./tmp
mkdir -p ./tmp
mkdir -p ./tmp/vaultwarden
docker cp "$id:/vaultwarden" ./tmp/vaultwarden/
docker cp "$id:/web-vault" ./tmp/vaultwarden/
docker rm -v "$id"

cd ./tmp/

./vaultwarden/vaultwarden --version | grep -Eo '[0-9]+.[0-9]+\.[0-9]+' >./vaultwarden/vaultwarden.version
cp -f ./vaultwarden/vaultwarden.version ../vaultwarden.version
cat >./vaultwarden/run.sh <<EOF
#!/bin/bash

vaultwarden
EOF

tar czf ../vaultwarden.tar.gz ./vaultwarden
cd ..
rm -rf ./tmp
