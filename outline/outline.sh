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

version=0.79.1
image_url=outlinewiki/outline
name=outline
copy_files=(
    # src dst pairs
    /opt/outline /outline
)
make_docker_tarball \
    $image_url:${version} \
    $name ${version} \
    "$entrypoint" "${copy_files[@]}"
