#!/usr/bin/env bash

set -e

cd "$(dirname "$0")"
pwd

find . -maxdepth 2 -mindepth 2 -type f -name '*.sh' -exec {} \;
