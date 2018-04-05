# Blockchain Provisioning

This repository contains:

1. Terraform scripts defining a set of AWS resources
1. Notes and documentation on how to use [puppeth](https://www.youtube.com/watch?v=T5RcjYPTG9g) to provision a private PoA ethereum blockchain on top of those resources

## Bringing Up the AWS environment

1. Install [terraform](https://www.terraform.io/)
1. Create an [aws credentials file](https://docs.aws.amazon.com/cli/latest/userguide/cli-config-files.html)
1. `terraform init`
1. `terraform apply`

## Logging into the AWS environment

1. You must have the private key for the `puppeth` aws keypair
1. `ssh -i <PRIVATE_KEY_PATH.pem> puppeth@<INSTANCE_PUBLIC_DNS>`
