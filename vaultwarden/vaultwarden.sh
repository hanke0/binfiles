#!/usr/bin/env bash

set -e

cd "$(dirname "$0")"
pwd

. ../lib.sh

entrypoint=$(
    cat <<EOF
#!/bin/sh

vaultwarden
EOF
)

version=1.31.0
make_docker_tarball \
    vaultwarden/server:${version}-alpine \
    vaultwarden ${version} \
    "$entrypoint" \
    /vaultwarden /vaultwarden/vaultwarden \
    /web-vault /vaultwarden/web-vault
