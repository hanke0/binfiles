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

make_docker_tarball \
    vaultwarden/server:1.30.1-alpine \
    vaultwarden 1.30.1 \
    "$entrypoint" \
    /vaultwarden /vaultwarden/vaultwarden \
    /web-vault /vaultwarden/web-vault
