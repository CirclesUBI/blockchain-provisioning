#! /bin/bash

# initializes geth datadir with genesis block

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
docker run -v "${script_dir}/data/sealer":/data/sealer -v "${script_dir}/data/genesis.json":/data/genesis.json ethereum/client-go --datadir /data/sealer init /data/genesis.json
