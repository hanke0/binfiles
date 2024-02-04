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
    ghcr.io/gethomepage/homepage:v0.8.7 \
    homepage 0.8.7 \
    "$entrypoint" \
    /app /homepage/app
