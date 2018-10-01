#! /bin/sh

SYNC_MODE=$1
NODE_NAME=$2

# GENESIS BLOCK
curl -o /genesis.json https://raw.githubusercontent.com/CirclesUBI/blockchain-provisioning/master/resources/genesis.json
geth init --datadir /data /genesis.json

# STATIC NETWORKING
echo '["enode://97ea1f0b1eada629dac3b24bcda9f61106f6b633fd1a6ed9180389219bdc4a9ad30933e85f8bf59e12893ea9dfd243a97de02445222941379cbe9eb0a0d31a52@[35.158.153.37]:30303"]' > /data/geth/static-nodes.json

# SYNC CLOCKS
ntpd /etc/ntpd.conf 

# START NODE
/usr/local/bin/geth \
    --datadir /data \
    --syncmode "${SYNC_MODE}" \
    --ethstats "${NODE_NAME}:76bGpbD3HxxE3vxz@$(dig +short stats.circles-chain.com | tr -d '[:space:]'):80" \
    --nodiscover \
    --rpc \
    --rpcaddr "0.0.0.0" \
    --rpccorsdomain="*" \
    --rpcapi admin,debug,miner,personal,txpool,eth,net,shh,web3 \
    --networkid 46781 \
    --nat extip:35.158.153.37
