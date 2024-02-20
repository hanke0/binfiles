#!/usr/bin/env bash

set -e

cd "$(dirname "$0")"
pwd

. ../lib.sh

entrypoint=$(
    cat <<EOF
#!/bin/sh

yarn start
EOF
)

make_docker_tarball \
    diygod/rsshub:latest \
    rsshub "$(date +%Y-%m-%d)" \
    "$entrypoint" \
    /app /rsshub
