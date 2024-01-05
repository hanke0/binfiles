#!/usr/bin/env bash
set -e

cd "$(dirname "$0")"
pwd
rm -rf ./tmp
mkdir -p ./tmp

tag=v2.10.1
docker pull yidadaa/chatgpt-next-web:$tag
id=$(docker create yidadaa/chatgpt-next-web:$tag)
docker cp "$id:/app" ./tmp/
docker rm -v "$id"
mv ./tmp/app ./tmp/chatgpt-next-web

echo "$tag" >"./tmp/chatgpt-next-web/chatgpt-next-web.version"
cp -f "./tmp/chatgpt-next-web/chatgpt-next-web.version" ./chatgpt-next-web.version
cat >"./tmp/chatgpt-next-web/run.sh" <<EOF
#!/usr/bin/env bash

node server.js
EOF
cd ./tmp/
tar czf ../chatgpt-next-web.tar.gz ./chatgpt-next-web
cd ../
rm -rf ./tmp
