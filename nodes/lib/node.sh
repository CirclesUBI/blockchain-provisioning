#! /bin/bash

set -e

NODE_TYPE=$1
NAME=$2

echo ${NAME}

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

docker build \
    -f "${SCRIPT_DIR}/node.dockerfile" \
    -t "circles-${NODE_TYPE}" \
    "${SCRIPT_DIR}"

docker run \
    -v "${SCRIPT_DIR}/../../circles-chain-data/${NAME}/":/data \
    -e NODE_NAME:"${NAME}" \
    -e NODE_TYPE="${NODE_TYPE}" \
    -p 8545:8545 \
    -p 30303:30303 \
    -p 30303:30303/udp \
    -it "circles-${NODE_TYPE}"
