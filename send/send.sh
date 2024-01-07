#!/bin/bash

set -e

cd "$(dirname "$0")"
pwd

. ../lib.sh

make_docker_tarball \
    registry.gitlab.com/timvisee/send:v3.4.23 \
    send v3.4.23 \
    /app /send
