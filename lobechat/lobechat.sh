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

make_docker_tarball \
    lobehub/lobe-chat:v0.123.0 \
    lobechat 0.123.0 \
    "$entrypoint" \
    /app /lobechat/app