#! /usr/bin/env sh

python3 /get_secret.py \
    --name "circles-ws-secret" \
    --value "ws-secret" \
    --output /secrets/ws-secret

if [ ! -d "/data/geth/chaindata" ]; then
    geth --datadir /data init /genesis.json
fi

geth \
    --syncmode "full" \
    --datadir "/data" \
    --ethstats "${SERVICE_NAME}:$(cat /secrets/ws-secret)@${ETHSTATS}" \
    --nodiscover
