// -----------------------------------------------------------------------------
// VARIABLES
// -----------------------------------------------------------------------------

variable "docker_compose_version" {
    default = "1.20.1"
}

variable "ethstats_port" {
    default = 3000
}

variable "region" {
    default = "eu-central-1"
}

variable "availability_zone" {
    default = "eu-central-1a"
}

// -----------------------------------------------------------------------------
// PROVIDERS
// -----------------------------------------------------------------------------

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
    region = "${var.region}"
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
// NODE
//
// Defines a single node running all services:
//
// 1. node is booted
// 2. cloud-init is run & bootstraps to docker-compose
// 3. docker-compose brings everything else up
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
        efs_id = "${aws_efs_file_system.circles.id}"
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
// PERSISTENT STORAGE
// -----------------------------------------------------------------------------

resource "aws_efs_file_system" "circles" {
    performance_mode = "maxIO"

    tags {
        Name = "circles-efs"
    }
}

resource "aws_efs_mount_target" "circles" {
  file_system_id = "${aws_efs_file_system.circles.id}"
  subnet_id      = "${aws_subnet.circles.id}"
  security_groups = ["${aws_security_group.circles_efs_mount_target.id}"]
}

// -----------------------------------------------------------------------------
// FIREWALL
// -----------------------------------------------------------------------------

resource "aws_security_group" "circles" {
    name = "circles"
    vpc_id = "${aws_vpc.circles.id}"

    ingress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "circles_efs_mount_target" {
    name = "circles_efs_mount_target"
    vpc_id = "${aws_vpc.circles.id}"

    ingress {
        from_port   = 2049
        to_port     = 2049
        protocol    = "TCP"
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
