FROM puppeth/explorer:latest

ADD ethstats.json /ethstats.json
ADD chainspec.json /chainspec.json

RUN \
  echo '(cd ../eth-net-intelligence-api && pm2 start /ethstats.json)' >  explorer.sh && \
	echo '(cd ../etherchain-light && npm start &)'                      >> explorer.sh && \
	echo '/parity/parity --bootnodes "enode://${bootnode_enode}@${bootnode_ip}:${bootnode_port}" --chain=/chainspec.json --tracing=on --fat-db=on --pruning=archive' >> explorer.sh

ENTRYPOINT ["/bin/sh", "explorer.sh"]
