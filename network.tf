// -----------------------------------------------------------------------------
// NETWORK
//
// Defines a VPC with a single publicly visible subnet
// see: https://ops.tips/blog/a-pratical-look-at-basic-aws-networking/
// -----------------------------------------------------------------------------

resource "aws_vpc" "circles" {
    cidr_block       = "10.0.0.0/16"
    enable_dns_support = true
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
