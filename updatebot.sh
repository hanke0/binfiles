#!/bin/bash

findversion() {
    local prefix version
    prefix="$2"
    if [ -z "$prefix" ]; then
        prefix="version="
    fi
    grep -o -E "${prefix}[0-9]+\.[0-9]+\.[0-9]+" "$1" | sed "s/${prefix}//g"
}

repos=(
    Yidadaa/ChatGPT-Next-Web "$(findversion chatgpt-next-web/chatgpt-next-web.sh)"
    dani-garcia/vaultwarden "$(findversion vaultwarden/vaultwarden.sh)"
    timvisee/send "$(findversion send/send.sh)"
    gethomepage/homepage "$(findversion homepage/homepage.sh)"
    sissbruecker/linkding "$(findversion linkding/linkding.sh)"
    lobehub/lobe-chat "$(findversion lobechat/lobechat.sh)"
    outline/outline "$(findversion outline/outline.sh)"
    koodo-reader/koodo-reader "$(findversion koodo-reader/koodo-reader.sh)"
)

trip_version() {
    grep -E -o '[0-9]+\.[0-9]+\.[0-9]+' <<<"$*"
}

# version_satisfy `nginx -v` 1.21.1
version_satisfy() {
    local v1 v2
    v1="$(trip_version "$1")"
    v2="$(trip_version "$2")"
    IFS=. read -r -a _target_version <<<"$v1"
    IFS=. read -r -a _compare_version <<<"$v2"
    for ((i = 0; i < ${#_compare_version[@]}; i++)); do
        if ((10#${_target_version[i]} == 10#${_compare_version[i]})); then
            continue
        fi
        if ((10#${_target_version[i]} > 10#${_compare_version[i]})); then
            continue
        fi
        return 1
    done
}

dorepo() {
    local data version url
    data=$(curl -sL --fail "https://api.github.com/repos/$1/releases/latest")
    if [ -z "$data" ]; then
        data=$(curl -sL --fail "https://api.github.com/repos/$1/tags")
        data=$(jq -r '.[0] | values' <<<"$data")
    fi
    version=$(jq -r ".name | values" <<<"$data")
    url=$(jq -r ".html_url | values" <<<"$data")
    if [ -z "$version" ]; then
        echo >&2 "Get $1 version fails"
        return
    fi
    if ! version_satisfy "$2" "$version"; then
        if [ -t 1 ]; then
            echo -e "\033[0;31m$1 has new release: $version, $url\033[0m"
        else
            echo "$1 has new release: $version, $url"
        fi
    else
        echo >&2 "$1 is latest: $version"
    fi
}

doall() {
    while [ $# -gt 0 ]; do
        if ! [[ "$2" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo >&2 "Cannot find version in $1"
            exit 1
        fi
        dorepo "$1" "$2"
        shift 2
    done
}

doall "${repos[@]}"
