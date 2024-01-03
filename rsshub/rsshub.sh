#!/usr/bin/env bash

set -e

cd "$(dirname "$0")"
pwd
docker pull diygod/rsshub:latest
id=$(docker create diygod/rsshub:latest)
rm -rf ./tmp
mkdir -p ./tmp
rm -rf ./tmp/app
docker cp "$id:/app" ./tmp/
docker rm -v "$id"
mv ./tmp/app ./tmp/rsshub
cd ./tmp
date +%Y-%m-%d >./rsshub/version.txt
cat >./rsshub/run.sh <<EOF
#!/bin/bash

yarn start
EOF

tar czf ../rsshub.tar.gz ./rsshub
cd ..
rm -rf ./tmp
