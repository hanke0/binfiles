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
dst=../chatgpt-next-web
rm -rf "$dst"
mkdir -p "$dst/public"
rsync -a ./public/ "$dst/public/"
rsync -a .next/standalone/ "$dst/"
mkdir -p "$dst/.next/static"
rsync -a .next/static/ "$dst/.next/static/"
mkdir -p "$dst/.next/server"
rsync -a .next/server/ "$dst/.next/server/"
echo "v2.10.1" >"$dst/chatgpt-next-web.version"
cp -f "$dst/chatgpt-next-web.version" ../../chatgpt-next-web.version
cat >"$dst/run.sh" <<EOF
#!/usr/bin/env bash

node server.js
EOF
cd ..
tar czf ../chatgpt-next-web.tar.gz ./chatgpt-next-web
cd ..
rm -rf ./tmp
