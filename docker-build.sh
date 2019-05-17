#!/bin/bash

THIS_DIR=$( (cd "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P) )

IMAGE_PREFIX=${IMAGE_PREFIX:-alpine-sshd}
IMAGE_TAG=${IMAGE_TAG:-latest}
IMAGE_NAME=${IMAGE_PREFIX}:${IMAGE_TAG}

set -e

set -x
docker build $NO_CACHE -t "${IMAGE_NAME}" "$THIS_DIR"
set +x
echo "Successfully built docker image $IMAGE_NAME"
