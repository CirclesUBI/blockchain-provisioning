# Blockchain Provisioning

This repository contains terraform scripts defining an AWS environment containing a private Ethereum blockchain

## Bringing Up the AWS environment

1. Install [terraform](https://www.terraform.io/)
1. Create an [aws credentials file](https://docs.aws.amazon.com/cli/latest/userguide/cli-config-files.html)
1. `terraform init`
1. `terraform apply`

## Running a Local Copy of the Infrastructure

1. Install [docker](https://docs.docker.com/install/) and [docker-compose](https://docs.docker.com/compose/install/)
1. `docker-compose up`

## Design Overview

- Single burstable EC2 instance. All services run in docker and coordinated with docker-compose.
- Data persisted and backed up using an EBS volume & snapshots.
- API gateway for routing.
- Geth chain using Cliqe PoA consensus.
- All changes to the infra go through git.
- No ssh access.
- Immutable (all changes trigger a full rebuild + atomic swap)

### Services

- bootnode (geth)
- miner (geth)
- monitoring dashboard (ethstats)
- block explorer (etherscan-light)

### Base VM Config

- Ubuntu 16.04 LTS
- Provisioned with cloud-config at boot-time

## TODO

- logging
- alerting
- secret management
  - ws_secret for ethstats
