FROM ethereum/client-go:v1.8.12

RUN apk update && apk add bind-tools curl

RUN curl -O https://raw.githubusercontent.com/CirclesUBI/blockchain-provisioning/master/resources/genesis.json
RUN geth init --datadir /data /genesis.json
RUN echo '["enode://2911761ebcfd615fff958ae989532e2b0aad29d0f2c6150a4b06d4a2e9830e3f67e346b59dea401f99ecc91332cf3dc0f3330657dad2ae3d43ad0c70bfa72c52@35.158.153.37:30303"]' > /data/geth/static-nodes.json

ENTRYPOINT ntpd /etc/ntpd.conf && /usr/local/bin/geth \
    --datadir /data \
    --syncmode "full" \
    --ethstats "${NODE_NAME}:76bGpbD3HxxE3vxz@$(dig +short stats.circles-chain.com | tr -d '[:space:]'):80" \
    --nodiscover \
    --rpc \
    --rpcapi admin,debug,miner,personal,txpool,eth,shh,web3 \
    --networkid 46781 \
    --nat extip:35.158.153.37 \
