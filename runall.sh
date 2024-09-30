#!/usr/bin/env bash

set -e

cd "$(dirname "$0")"
pwd

rm -rf dist
mkdir -p dist

files=$(find . -maxdepth 2 -mindepth 2 -type f -name '*.sh')
for f in $files; do
    name=$(basename "$f")
    name="${name%.*}"
    echo "--- $f ----"
    chmod +x "$f"
    "$f"
    echo "--- $f Exit $? ----"
    mv "${name}/${name}.tar.gz" "${name}/${name}.version" dist/
done
