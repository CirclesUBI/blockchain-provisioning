// -----------------------------------------------------------------------------
// NETWORK
//
// Defines a VPC with a single publicly visible subnet
// see: https://ops.tips/blog/a-pratical-look-at-basic-aws-networking/
// -----------------------------------------------------------------------------

resource "aws_vpc" "circles" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags {
    Name = "circles-vpc"
  }
}

resource "aws_subnet" "circles" {
  vpc_id                  = "${aws_vpc.circles.id}"
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "${var.availability_zone}"
  map_public_ip_on_launch = true

  tags {
    Name = "circles-subnet"
  }
}

resource "aws_internet_gateway" "circles" {
  vpc_id = "${aws_vpc.circles.id}"

  tags {
    Name = "circles-internet-gateway"
  }
}

resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.circles.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.circles.id}"
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
