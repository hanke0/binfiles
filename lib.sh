#!/usr/bin/env bash

docker_dest=./tmp/docker

make_docker_tarball() {
    local image name version entrypoint
    image="$1"
    name="$2"
    version="$3"
    entrypoint="$4"
    shift 4

    clean_docker
    mkdir -p "$docker_dest/$name"
    extract_from_docker_image "$image" "$@"
    write_version_into_docker "$name" "$version"
    echo "$entrypoint" >"$docker_dest/$name/run.sh"
    make_tarball_from_docker "$name"
}

clean_docker() {
    rm -rf "$docker_dest"
    mkdir -p "$docker_dest"
}

extract_from_docker_image() {
    local image
    image="$1"
    shift
    docker pull -q "$image"
    id=$(docker create "$image")

    while [ $# -gt 0 ]; do
        docker cp "$id:$1" "$docker_dest/$2"
        shift 2
    done
    docker rm -v "$id"
}

write_version_into_docker() {
    local name version

    name="$1"
    version="$2"
    echo "$version" >"$docker_dest/$name/$name.version"
    cp -f "$docker_dest/$name/$name.version" "./$name.version"
}

make_tarball_from_docker() {
    tar -C "$docker_dest" -czf "./$1.tar.gz" .
}
