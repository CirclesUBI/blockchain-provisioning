#! /bin/sh

SYNCMODE=$1
NODE_NAME=$2

# GENESIS BLOCK
curl -o /genesis.json https://raw.githubusercontent.com/CirclesUBI/blockchain-provisioning/master/resources/genesis.json
geth init --datadir /data /genesis.json

# STATIC NETWORKING
echo '["enode://56547161104f44313b49447661bb595e30e663d98abec141cdab93b36dcd076bb449e78ceee3d8e5925cc63bb181b37560f360ebc2e58e0addb4d5dc06de9734@[35.158.153.37]:30303"]' > /data/geth/static-nodes.json

# SYNC CLOCKS
ntpd /etc/ntpd.conf 

# START NODE
/usr/local/bin/geth \
    --datadir /data \
    --syncmode "${SYNCMODE}" \
    --ethstats "${NODE_NAME}:76bGpbD3HxxE3vxz@$(dig +short stats.circles-chain.com | tr -d '[:space:]'):80" \
    --nodiscover \
    --rpc \
    --rpcaddr "0.0.0.0" \
    --rpcapi admin,debug,miner,personal,txpool,eth,shh,web3 \
    --networkid 46781 \
    --nat extip:35.158.153.37
