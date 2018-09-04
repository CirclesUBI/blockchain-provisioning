terraform {
  backend "s3" {
    bucket = "circles-terraform"
    region = "us-east-1"

    key            = "circles-terraform.tfstate"
    dynamodb_table = "circles-terraform"
    encrypt        = true
    profile        = "circles-blockchain-provisioning"
  }
}

provider "aws" {
  region  = "${var.region}"
  profile = "circles-blockchain-provisioning"
}
