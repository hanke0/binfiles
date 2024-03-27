#!/usr/bin/env bash
set -e

cd "$(dirname "$0")"
pwd

. ../lib.sh

entrypoint=$(
    cat <<EOF
#!/bin/sh

node server.js
EOF
)

version=2.11.3
tag=v${version}
make_docker_tarball \
    yidadaa/chatgpt-next-web:$tag \
    chatgpt-next-web $tag \
    "$entrypoint" \
    /app /chatgpt-next-web
