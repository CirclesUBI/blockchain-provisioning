#! /usr/bin/env sh

python3 /get_secret.py \
    --name "circles-ws-secret" \
    --value "ws-secret" \
    --output /secrets/ws-secret

geth \
    --syncmode "full" \
    --datadir "/chain" \
    --ethstats "${SERVICE_NAME}:$(cat /secrets/ws-secret)@${ETHSTATS}" \
    --nodiscover

