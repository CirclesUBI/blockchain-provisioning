terraform {
  backend "s3" {
    bucket = "circles-terraform"
    region = "us-east-1"

    key    = "circles-terraform.tfstate"
    dynamodb_table = "circles-terraform"
    encrypt = true
  }
}

provider "aws" {
    region = "eu-central-1"
}

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
    map_public_ip_on_launch = true
    availability_zone = "eu-central-1b"

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
// NODE
//
// Defines a single node running all services:
//
// 1. node is booted
// 2. cloud-init is run & bootstraps to docker-compose
// 3. docker-compose brings everything else up
// -----------------------------------------------------------------------------

variable "docker_compose_version" {
    default = "1.20.1"
}

// -----------------------------------------------------------------------------

data "aws_ami" "ec2-linux" {
    most_recent = true

    filter {
        name = "name"
        values = ["amzn-ami-*-x86_64-gp2"]
    }

    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }

    filter {
        name = "owner-alias"
        values = ["amazon"]
    }
}

data "template_file" "cloud_init" {
    template = "${file("${path.module}/cloud-init.yaml")}"

    vars {
        docker_compose_file = "${file("${path.module}/docker-compose.yaml")}"
        docker_compose_version = "${var.docker_compose_version}"
    }
}

resource "aws_instance" "circles" {
    instance_type = "t2.micro"
    ami = "${data.aws_ami.ec2-linux.id}"

    user_data = "${data.template_file.cloud_init.rendered}"

    subnet_id = "${aws_subnet.circles.id}"
    vpc_security_group_ids = ["${aws_security_group.circles.id}"]
    associate_public_ip_address = true

    tags {
        Name = "circles"
    }
}

// -----------------------------------------------------------------------------
// FIREWALL
// -----------------------------------------------------------------------------

variable "ethstats_port" {
    default = 3000
}

// -----------------------------------------------------------------------------

resource "aws_security_group" "circles" {
    name = "circles"
    vpc_id = "${aws_vpc.circles.id}"

    ingress {
        from_port   = "${var.ethstats_port}"
        to_port     = "${var.ethstats_port}"
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

// -----------------------------------------------------------------------------
// OUTPUTS
// -----------------------------------------------------------------------------

output "ethstats" {
  value = "${aws_instance.circles.public_dns}:3000"
}
