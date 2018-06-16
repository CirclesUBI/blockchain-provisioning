FROM ethereum/client-go:release-1.8

VOLUME /data

ARG service_name=${service_name}

COPY resources/get_secret.py /get_secret.py
COPY resources/static-nodes.json /data/geth/static-nodes.json
COPY resources/genesis.json /genesis.json

RUN apk add --no-cache python3
RUN pip3 install --upgrade pip
RUN pip3 install boto3

COPY services/full_node/entrypoint.sh /entrypoint.sh

ENTRYPOINT sh /entrypoint.sh
