# Design Overview

Single burstable EC2 instance. All services run in docker and coordinated with docker-compose.

Data persisted and backed up using an EBS volume & snapshots.

API gateway for routing.

Parity chain using Aura PoA consensus.

No ssh access. All changes to the infra go through git.

## Services

- bootnode (parity)
- miner (parity)
- ethstats
- block explorer (etherscan-light)
