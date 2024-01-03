#!/usr/bin/env bash
set -e

cd "$(dirname "$0")"
pwd
rm -rf ./tmp
mkdir -p ./tmp

# v2.10.1
git clone -b v2.10.1 https://github.com/Yidadaa/ChatGPT-Next-Web \
    ./tmp/chatgptnextweb

cd ./tmp/chatgptnextweb
git reset --hard d17000975fe58c84e576f89be552c76b91bcb827
yarn install
yarn build
dst=./tmp/chatgpt-next-web
rm -rf "$dst"
mkdir -p "$dst/public"
rsync -a ./public/ "$dst/public/"
rsync -a .next/standalone/ "$dst/"
mkdir -p "$dst/.next/static"
rsync -a .next/static/ "$dst/.next/static/"
mkdir -p "$dst/.next/server"
rsync -a .next/server/ "$dst/.next/server/"
echo "v2.10.1" >"$dst/version.txt"
cp -f "$dst/version.txt" ./chatgpt-next-web.version
cat >"$dst/run.sh" <<EOF
#!/usr/bin/env bash

node server.js
EOF
cd ./tmp
tar czf ../chatgpt-next-web.tar.gz ./chatgpt-next-web
rm -rf ./tmp
