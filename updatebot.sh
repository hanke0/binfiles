#!/bin/bash

repos=(
    Yidadaa/ChatGPT-Next-Web 2.10.1
    dani-garcia/vaultwarden 1.30.3
    timvisee/send 3.4.23
    aaamoon/copilot-gpt4-service 0.1.0
    gethomepage/homepage 0.8.7
    sissbruecker/linkding 1.24.0
)

trip_version() {
    grep -P -o '\d+\.\d+\.\d+' <<<"$*"
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
    data=$(curl -sSL --fail "https://api.github.com/repos/$1/releases/latest")
    if [ -z "$data" ]; then
        data=$(curl -sSL --fail "https://api.github.com/repos/$1/tags")
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
        dorepo "$1" "$2"
        shift 2
    done
}

doall "${repos[@]}"
