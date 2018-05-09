# Blockchain Provisioning

This repository contains terraform scripts defining an AWS environment containing a private Ethereum blockchain

## Bringing Up the AWS environment

1. Install [terraform](https://www.terraform.io/)
1. Create an [aws credentials file](https://docs.aws.amazon.com/cli/latest/userguide/cli-config-files.html)
1. `terraform init`
1. `terraform apply`

### Services

- bootnode (geth)
- sealer (geth)
- rpc relay node (geth)
- monitoring dashboard (ethstats)
- block explorer (etherchain-light)

### TODO

- [ ] RPC node is not relaying transactions to sealer
- [ ] Backup chain data
- [ ] Services should not be run as root
- [ ] Elastic IP for public nodes
- [ ] Split network into public / private subnets
