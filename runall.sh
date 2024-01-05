#!/usr/bin/env bash

set -e

cd "$(dirname "$0")"
pwd

files=$(find . -maxdepth 2 -mindepth 2 -type f -name '*.sh')
for f in $files; do
    echo "--- $f ----"
    "$f"
    echo "--- $f Exit $? ----"
done
