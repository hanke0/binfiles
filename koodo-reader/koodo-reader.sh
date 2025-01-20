#!/usr/bin/env bash

set -e

cd "$(dirname "$0")"
pwd

. ../lib.sh

entrypoint=$(
    cat <<'EOF1'
EOF1
)

version=1.7.4
make_docker_tarball \
    googletranslate/koodo-reader:v${version} \
    koodo-reader ${version} \
    "$entrypoint" \
    /usr/share/nginx/html /koodo-reader
