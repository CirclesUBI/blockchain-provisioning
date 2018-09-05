#! /bin/bash

set -e

SYNC_MODE=$1
NODE_NAME=$2

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

docker build \
    -f "${SCRIPT_DIR}/node.dockerfile" \
    -t "circles-node" \
    "${SCRIPT_DIR}"

docker run \
    -v "${SCRIPT_DIR}/../../circles-chain-data/${NODE_NAME}/":/data \
    -e NODE_NAME="${NODE_NAME}" \
    -e SYNC_MODE="${SYNC_MODE}" \
    -p 8545:8545 \
    -p 30303:30303 \
    -p 30303:30303/udp \
    -it "circles-node"
