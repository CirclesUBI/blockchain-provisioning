// -----------------------------------------------------------------------------
// VPC
// -----------------------------------------------------------------------------

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "1.32.0"

  name = "circles-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.availability_zone}"]
  private_subnets = ["10.0.1.0/24"]
  public_subnets  = ["10.0.101.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = false
}

locals {
  public_subnet_id = "${module.vpc.public_subnets[0]}"
  private_subnet_id = "${module.vpc.private_subnets[0]}"
}

// -----------------------------------------------------------------------------
// DNS
// -----------------------------------------------------------------------------

resource "aws_route53_zone" "circles" {
  name = "${var.domain}"
}

resource "aws_route53_record" "ethstats" {
  zone_id = "${aws_route53_zone.circles.zone_id}"
  name    = "stats.${var.domain}"
  type    = "A"
  ttl     = "300"
  records = ["${module.ethstats.public_ip}"]
}

resource "aws_route53_record" "bootnode" {
  zone_id = "${aws_route53_zone.circles.zone_id}"
  name    = "boot.${var.domain}"
  type    = "A"
  ttl     = "300"
  records = ["${module.bootnode.public_ip}"]
}

resource "aws_route53_record" "explorer" {
  zone_id = "${aws_route53_zone.circles.zone_id}"
  name    = "explorer.${var.domain}"
  type    = "A"
  ttl     = "300"
  records = ["${module.explorer.public_ip}"]
}

// -----------------------------------------------------------------------------
// Static IP
// -----------------------------------------------------------------------------

resource "aws_eip" "rpc" {
  instance = "${module.rpc.instance_id}"
  vpc      = true

  tags {
    Name = "circles-rpc"
  }
}
