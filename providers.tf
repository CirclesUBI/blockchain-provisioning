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
