#!/bin/bash

THIS_DIR=$( (cd "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P) )

IMAGE_PREFIX=${IMAGE_PREFIX:-alpine-sshd}
IMAGE_TAG=${IMAGE_TAG:-latest}
IMAGE_NAME=${IMAGE_PREFIX}:${IMAGE_TAG}

read-keys() {
    local key_dir=$1
    local keys key
    if [[ -d "$key_dir" ]]; then
        for f in "$key_dir"/*.pub; do
            if [[ -r "$f" ]]; then
                key="$(< "$f")"
                if [[ -z "$keys" ]]; then
                    keys=$key
                elif [[ "$keys" == *$'\n' ]]; then
                keys="${keys}${key}"
                else
                    keys="${keys}$'\n'${key}"
                fi
            fi
        done
    fi
    echo "$keys"
}

cd "$THIS_DIR"
ARGS=()
OPENSSH_AUTHORIZED_KEYS="$(read-keys keys)"
OPENSSH_ROOT_AUTHORIZED_KEYS="$(read-keys root-keys)"

set -xe
docker run -p 2222:22 "${ARGS[@]}" \
       -e OPENSSH_AUTHORIZED_KEYS="$OPENSSH_AUTHORIZED_KEYS" \
       -e OPENSSH_ROOT_AUTHORIZED_KEYS="$OPENSSH_ROOT_AUTHORIZED_KEYS" \
       --name=alpine-sshd \
       --rm -ti "${IMAGE_NAME}" "$@"
