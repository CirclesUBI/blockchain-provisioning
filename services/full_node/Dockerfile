FROM ethereum/client-go

COPY /get_secret.py /get_secret.py
VOLUME /chain

RUN apk add --no-cache python3
RUN pip3 install boto3

RUN echo 'python3 /get_secret.py \
    --name "circles-ws-secret" \
    --value "ws-secret" \
    --output /secrets/ws-secret' \
    >> /entrypoint.sh

RUN echo 'cp /static_nodes.json /chain/geth/static-nodes.json'\
    >> /entrypoint.sh

RUN echo 'echo "STATIC_NODES:"'\
    >> /entrypoint.sh

RUN echo 'cat /chain/geth/static-nodes.json'\
    >> /entrypoint.sh

RUN echo 'geth \
    --syncmode "full" \
    --networkid "${network_id}" \
    --datadir "/chain" \
    --ethstats "${service_name}:$(cat /secrets/ws-secret)@${ethstats}" \
    --nodiscover' \
    >> /entrypoint.sh

ENTRYPOINT sh /entrypoint.sh
