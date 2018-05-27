FROM ethereum/client-go

COPY /get_secret.py /get_secret.py
VOLUME /chain

RUN apk add --no-cache python3
RUN pip3 install boto3

ENTRYPOINT geth --datadir /chain init /genesis.json && python3 /get_secret.py --name "circles-ws-secret" --value "ws-secret" --output /secrets/ws-secret && sh -c 'geth --maxpeers 1000 --syncmode "full" --networkid "${network_id}" --datadir "/chain" --keystore "/keystore" --ethstats "${service_name}:$(cat /secrets/ws-secret)@${ethstats}" --bootnodes "${bootnode}"'
