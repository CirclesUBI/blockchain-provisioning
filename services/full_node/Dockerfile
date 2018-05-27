FROM ethereum/client-go

ARG ethstats
ARG bootnode
ARG network_id

COPY /get_secret.py /get_secret.py
VOLUME /chain

RUN apk add --no-cache python3
RUN pip3 install boto3

ENTRYPOINT python3 /get_secret.py --name "circles-ws-secret" --value "ws-secret" --output /secrets/ws-secret && sh -c 'geth --maxpeers 1000 --syncmode "full" --networkid "${network_id}" --datadir "/chain" --keystore "/keystore" --ethstats "rpc:$(cat /secrets/ws-secret)@${ethstats}" --bootnodes "enode://${bootnode_enode}@${bootnode_ip}:${bootnode_port}"'
