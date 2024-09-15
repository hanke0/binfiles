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

version=1.17.6
make_docker_tarball \
    lobehub/lobe-chat:v${version} \
    lobechat ${version} \
    "$entrypoint" \
    /app /lobechat/app
