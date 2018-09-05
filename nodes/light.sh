#! /usr/bin/env bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

bash "${SCRIPT_DIR}/lib/node.sh" "light" "${NAME}"
