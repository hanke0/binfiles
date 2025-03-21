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

version=1.0.2
make_docker_tarball \
    ghcr.io/gethomepage/homepage:v${version} \
    homepage ${version} \
    "$entrypoint" \
    /app /homepage/app
