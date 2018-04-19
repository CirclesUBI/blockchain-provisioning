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
        init_chain_sh = "${file("${path.module}/init_chain.sh")}"
        genesis_json = "${file("${path.module}/genesis.json")}"
        get_secrets_py = "${file("${path.module}/get_secrets.py")}"
        docker_compose_version = "${var.docker_compose_version}"
        efs_id = "${aws_efs_file_system.circles.id}"
    }
}

// we use the template_cloudinit_config to gzip compress the cloud-init file (it's too big otherwise)
data "template_cloudinit_config" "cloud_init" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = "${data.template_file.cloud_init.rendered}"
  }
}

resource "aws_instance" "circles" {
    instance_type = "t2.micro"
    ami = "${data.aws_ami.ec2-linux.id}"

    user_data = "${data.template_cloudinit_config.cloud_init.rendered}"

    iam_instance_profile = "${aws_iam_instance_profile.circles.name}"

    subnet_id = "${aws_subnet.circles.id}"
    vpc_security_group_ids = ["${aws_security_group.circles.id}"]
    associate_public_ip_address = true

    tags {
        Name = "circles"
    }
}

// -----------------------------------------------------------------------------
// SECRETS
//
// Defines an IAM instance provile that allows the node to read secrets from
// AWS secrets manager
// -----------------------------------------------------------------------------

resource "aws_iam_instance_profile" "circles" {
  name  = "circles-secrets"
  role = "${aws_iam_role.circles.name}"
}

resource "aws_iam_role" "circles" {
  name = "circles-secrets"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_policy_attachment" "circles" {
  name       = "circles-secrets"
  roles      = ["${aws_iam_role.circles.name}"]
  policy_arn = "${aws_iam_policy.circles.arn}"
}

resource "aws_iam_policy" "circles" {
    name = "circles-secrets"

    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "secretsmanager:GetSecretValue",
            "Resource": "arn:aws:secretsmanager:eu-central-1:574150460280:secret:circles-secrets-zr9x30"
        }
    ]
}
EOF
}

// -----------------------------------------------------------------------------
// PERSISTENT STORAGE
// -----------------------------------------------------------------------------

resource "aws_efs_file_system" "circles" {
    performance_mode = "maxIO"

    lifecycle {
        prevent_destroy = true
    }

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
        from_port   = "${var.ethstats_port}"
        to_port     = "${var.ethstats_port}"
        protocol    = "TCP"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = "${var.bootnode_port}"
        to_port     = "${var.bootnode_port}"
        protocol    = "UDP"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = "${var.geth_port}"
        to_port     = "${var.geth_port}"
        protocol    = "TCP"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = "${var.geth_port}"
        to_port     = "${var.geth_port}"
        protocol    = "UDP"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = "${var.geth_rpc_port}"
        to_port     = "${var.geth_rpc_port}"
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
