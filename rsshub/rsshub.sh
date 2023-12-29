#!/usr/bin/env bash

set -e

cd "$(dirname "$0")"
pwd
docker pull diygod/rsshub:latest
id=$(docker create diygod/rsshub:latest)
mkdir -p ./tmp
rm -rf ./tmp/app
docker cp "$id:/app" ./tmp/
docker rm -v "$id"
mv ./tmp/app ./tmp/rsshub
cd ./tmp
tar czf ../rsshub.$(date +%Y-%m-%d).tar.gz ./rsshub
rm -rf ./tmp
