#! /usr/bin/env sh

python3 /get_secret.py \
    --name "circles-ws-secret" \
    --value "ws-secret" \
    --output /secrets/ws-secret

rm -rf /data/**/*

cat /genesis.json
geth init --datatdir /data/ /genesis.json

geth \
    --syncmode "full" \
    --datadir "/data" \
    --ethstats "${SERVICE_NAME}:$(cat /secrets/ws-secret)@${ETHSTATS}" \
    --nodiscover
