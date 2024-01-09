#!/usr/bin/env bash

set -e

cd "$(dirname "$0")"
pwd

mkdir -p ./tmp/app/copilot-gpt4
export GOBIN="$(pwd)/tmp/app/copilot-gpt4"
export GOMODCACHE="$(pwd)/tmp/gocache"
tag=0.1.0
go mod download github.com/aaamoon/copilot-gpt4-service@$tag

cd ./tmp/gocache/github.com/aaamoon/copilot-gpt4-service@v0.0.0-20240109034825-c362c7f7fdc6
export GOOS=linux
export GOARCH=amd64
CGO_ENABLED=0 go build -o ../../../../../tmp/app/copilot-gpt4/copilot-gpt4 .
cd ../../../../..

echo "$tag" >./tmp/app/copilot-gpt4/copilot-gpt4.version
cat >./tmp/app/copilot-gpt4/run.sh <<EOF
#!/bin/sh

export HOST=localhost
export PORT=10023
export CACHE=true
export CACHE_PATH=./cache.db

copilot-gpt4
EOF
cp -f ./tmp/app/copilot-gpt4/copilot-gpt4.version ./copilot-gpt4.version
tar -C "./tmp/app" -czf "./copilot-gpt4.tar.gz" .
