// -----------------------------------------------------------------------------
// VARIABLES
// -----------------------------------------------------------------------------

variable "docker_compose_version" {
  default = "1.20.1"
}

variable "ethstats_port" {
  default = 3000
}

variable "bootnode_port" {
  default = 30301
}

variable "geth_port" {
  default = 30303
}

variable "geth_rpc_port" {
  default = 8545
}

variable "region" {
  default = "eu-central-1"
}

variable "availability_zone" {
  default = "eu-central-1a"
}

// -----------------------------------------------------------------------------
// DEBUG
// -----------------------------------------------------------------------------

resource "aws_key_pair" "david" {
  key_name   = "circles-david"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDhhDFjm/ZOVN3j1a10ZLr8az2Kcg0uHKn4tOKLJx8vzBnetiLqr6VEWlEv/mOyxjhSr50RWUrweyJZMYmKu3uIZdhj8xlnpF+BrHbdP3YTNPupzONoE4Fz19GxFDh0eCYRINLiOun7DfFRSPx+QTl3sLLuivBvJg6bWUciDJ5I5OaXSVoRi/No+GW1+LH8L0zrSyEXOe7uVkkA9dz0yqw+Aciu6tJPZFVdHgYt6lA5UtNAjb9zTTId7wIeWp/IG1m24AEKQO7vs+YBQz2v4PKdf/vzXiq1Rwo1YvScTl1GnrP3nXJZmgjEmvg1ZDdpq+ywySTCwghwKCqo6rp36oXkL2buVBEQ/fti76R+9M+bAqWD1x6T/hRf6ia/wSZmeVC+a7SUD5yHAB1u5FgC6kOLvnInf4lI7Y7pL1zfgsmIU63dTE3WQa1lcchhqRP2XcuPwZy1U084yho11pLyisGLufwRrT+jRvf7ii/5Cw9BAH2oKrWqcdIpTBKAwZUtK5dap/Tzyv1/GNzPWoE3yTtrHK5c18fgpoYQ+Sutc55QnIZhqlioFMOgbzMYbVtUSD8MwXSLtXE9lwoCDoQAJfhmgIPDWZwtyJwF/qSbE4+S27SETobx8bAWmX0eAcIE++8OYcNHuvDYIHq7Ei6R6N0GBjF+cl7zmnfsC6YIrh03tw== davidterry@posteo.de"
}

// -----------------------------------------------------------------------------
// PROVIDERS
// -----------------------------------------------------------------------------

terraform {
  backend "s3" {
    bucket = "terraform-circles"
    region = "eu-central-1"

    // bucket = "circles-terraform"
    // region = "us-east-1"

    key            = "circles-terraform.tfstate"
    dynamodb_table = "circles-terraform"
    encrypt        = true
  }
}

provider "aws" {
  region = "${var.region}"
}
