#!/bin/bash

set -e

cd "$(dirname "$0")"
pwd

. ../lib.sh

entrypoint=$(
    cat <<EOF
#!/bin/sh

node server/bin/prod.js
EOF
)

version=3.4.23
tag=v${version}

make_docker_tarball \
    registry.gitlab.com/timvisee/send:$tag \
    send $tag \
    "$entrypoint" \
    /app /send
