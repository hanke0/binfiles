#!/usr/bin/env bash

set -e

cd "$(dirname "$0")"
pwd

. ../lib.sh

entrypoint=$(
    cat <<'EOF1'
#!/usr/bin/env bash
set -e
node ./build/server/index.js
EOF1
)

version=0.76.1
make_docker_tarball \
    outlinewiki/outline:${version} \
    lobechat ${version} \
    "$entrypoint" \
    /opt/outline /outline
