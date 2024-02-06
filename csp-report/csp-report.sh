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
    metlo/csp-service:v0.8.7 \
    homepage 0.8.7 \
    "$entrypoint" \
    /app /homepage/app
