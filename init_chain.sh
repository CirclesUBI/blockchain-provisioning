#! /bin/bash

# initializes geth datadir with genesis block

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
docker run -v "${script_dir}/data/sealer":/data/sealer:Z -v "${script_dir}/genesis.json":/genesis.json:ro ethereum/client-go --datadir /data/sealer init /genesis.json
