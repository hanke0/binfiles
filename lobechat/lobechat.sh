#!/usr/bin/env bash

set -e

cd "$(dirname "$0")"
pwd

. ../lib.sh

entrypoint=$(
    cat <<'EOF1'
#!/usr/bin/env bash
set -e
node server.js
EOF1
)

version=0.133.0
make_docker_tarball \
    lobehub/lobe-chat:v${version} \
    lobechat ${version} \
    "$entrypoint" \
    /app /lobechat/app
