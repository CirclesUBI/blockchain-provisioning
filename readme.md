# Blockchain Provisioning

This repository contains [terraform](https://www.terraform.io/) scripts defining an AWS environment containing a private Ethereum blockchain

## Using the Cluster

- Monitor the current status of the cluster with our ethstats instance at: http://18.184.187.168:3000
- Connect metamask to the RPC node at: http://18.184.227.148:8545
- Connect your own node to the cluster using the [`gensis.json`](resources/genesis.json) and the bootnode at [35.157.62.211](35.157.62.211)

## Bringing Up the AWS environment

1. Install [terraform](https://www.terraform.io/)
1. Create an [aws credentials file](https://docs.aws.amazon.com/cli/latest/userguide/cli-config-files.html)
1. `terraform init`
1. `terraform apply`

## Operating the Cluster

- aside from a few exceptions (see below) this git repository should fully and completly describe the cluster and all associated AWS infrastructure
- updates to the cluster should only be applied by changing the source code and running `terraform apply`
- instances are [immutable](https://www.digitalocean.com/community/tutorials/what-is-immutable-infrastructure) (never modified after they are deployed)
- if an instance needs to be changed then it will be destroyed and an updated replacement will be built from source and deployed

### Manually Provisioned Resources

#### Terraform State and Locking Table

- state is persisted to an encrypted & versioned S3 bucket
- in order to reduce the risk that a bad commit could destroy the state the required resources (S3 bucket + dynamoDB table) are managed outside of Terraform
- specified in [providers.tf](providers.tf)
- docs: [state](https://www.terraform.io/docs/state/index.html) | [backends](https://www.terraform.io/docs/backends/index.html)

#### Secrets

- due to the [risk of leaking state](https://www.terraform.io/docs/state/sensitive-data.html), all sensistive information should be managed outside of Terraform
- Stored in [Secrets Manager](https://aws.amazon.com/secrets-manager/)
- Pulled onto servers with a [python script](services/base/get_secret.py) using IAM roles defined in [iam.tf](secrets.tf)

#### EFS Folder Structure

- Directories in EFS can only be created by mounting an instance and running `mkdir`.
- Nodes share the same EFS volume but only mount subdirectories. Subdirectories cannot be mounted until they actually exist.
- EFS volume needs `/sealer` and `/rpc` directories (should be empty)

## Environment / Topology

### Data Persistance

- defined in [storage.tf](storage.tf)
- all state is persisted in a single EFS filesystem volume

### Consensus Parameters

- defined in [resources/genesis.json](resources/genesis.json)
- proof of Authority chain using geth with [Clique](https://github.com/ethereum/EIPs/issues/225).
- 5s block times

### Network

- defined in [network.tf](network.tf)
- 1 internet visible subnet inside 1 vpc. (eu-central-1a)

### Logging

- cloud-init logs for each instance written to cloudwatch logs

## Services

Each service runs on a single burstable t2.micro instance (defined in [services/base.tf](services/base/main.tf)).

### [sealer](services/sealer/main.tf)

- produces blocks
- holds private keys
- running geth

### [rpc](services/rpc/main.tf)

- rpc ports opened to public internet
- relays blocks to sealer
- allows interaction with metamask
- running geth

### [bootnode](services/bootnode/main.tf)

- service discovery
- requires open udp ports to the network
- running geth

### [ethstats](services/ethstats.tf)

- monitoring dashboard for the cluster
- running [eth-netstats](https://github.com/cubedro/eth-netstats)

## TODO

- [ ] Log file will grow forever
- [ ] Unify geth version parameters
- [ ] Define staging environment
- [ ] Backup chain data
- [ ] Services should not be run as root
- [ ] Split network into public / private subnets
- [ ] Use systemd to autorestart failed processes
- [ ] Automate secret rotation
