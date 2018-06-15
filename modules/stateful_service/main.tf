// A stateful_service is a single ec2 with a dettachable EBS volume and network interface

# ----------------------------------------------------------------------------------------------
# inputs

variable "service_name" {}

variable "ecs_cluster" {}

variable "vpc_id" {}
variable "subnet_id" {}
variable "availability_zone" {}

variable "ip_address" {
  description = "static and persistant ipv4 address. An ENI for this ip address will be created and attached"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "ingress_rules" {
  type        = "list"
  default     = []
  description = "ingress rules to be added to the instance security group"
}

# ----------------------------------------------------------------------------------------------
# Instance

resource "aws_instance" "this" {
  ami           = "${data.aws_ami.ecs_optimized.id}"
  instance_type = "${var.instance_type}"

  iam_instance_profile = "${aws_iam_instance_profile.this.name}"

  subnet_id              = "${var.subnet_id}"
  vpc_security_group_ids = ["${aws_security_group.this.id}"]

  user_data = "${data.template_file.cloud_config.rendered}"

  tags {
    Name = "circles-${var.service_name}"
  }
}

# ----------------------------------------------------------------------------------------------
# Storage

resource "aws_ebs_volume" "this" {
  availability_zone = "${var.availability_zone}"
  size              = 100
  type              = "io1"
  iops              = 1000

  lifecycle {
    prevent_destroy = true
  }

  tags {
    Name = "circles-${var.service_name}"
  }
}

# ----------------------------------------------------------------------------------------------
# Static IP

resource "aws_network_interface" "this" {
  subnet_id       = "${var.subnet_id}"
  private_ips     = ["${var.ip_address}"]
  security_groups = ["${aws_security_group.this.id}"]

  tags {
    Name = "circles-${var.service_name}"
  }
}

# ----------------------------------------------------------------------------------------------
# AMI

data "aws_ami" "ecs_optimized" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn-ami-*-amazon-ecs-optimized"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
}

# ----------------------------------------------------------------------------------------------
# user data

data "template_file" "awslogs_conf" {
  template = "${file("${path.module}/awslogs.conf")}"

  vars {
    service_name = "${var.service_name}"
    dmesg        = "/var/log/dmesg"
    messages     = "/var/log/messages"
    cloud_init   = "/var/log/cloud-init-output.log"
    docker       = "/var/log/docker"
  }
}

data "template_file" "cloud_config" {
  template = "${file("${path.module}/cloud-config.yaml")}"

  vars {
    awslogs_conf        = "${data.template_file.awslogs_conf.rendered}"
    attach_resources_py = "${file("${path.module}/attach_resources.py")}"
    eni_id              = "${aws_network_interface.this.id}"
    volume_id           = "${aws_ebs_volume.this.id}"
  }
}

# ----------------------------------------------------------------------------------------------
# IAM

resource "aws_iam_instance_profile" "this" {
  name = "circles-${var.service_name}"
  role = "${aws_iam_role.this.name}"
}

data "aws_iam_policy_document" "instance_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "circles-${var.service_name}"
  assume_role_policy = "${data.aws_iam_policy_document.instance_assume_role_policy.json}"
}

resource "aws_iam_role_policy" "logs" {
  name = "circles-${var.service_name}-logs"
  role = "${aws_iam_role.this.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Effect": "Allow",
        "Action": [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "logs:DescribeLogStreams"
        ],
        "Resource": [
            "arn:aws:logs:*:*:*"
        ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "network_interface" {
  name = "circles-${var.service_name}-network-interface"
  role = "${aws_iam_role.this.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:AttachNetworkInterface",
        "ec2:AttachVolume",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DescribeVolumes"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "ecs" {
  name = "circles-${var.service_name}-ecs"
  role = "${aws_iam_role.this.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "ecs:DeregisterContainerInstance",
          "ecs:DiscoverPollEndpoint",
          "ecs:Poll",
          "ecs:RegisterContainerInstance",
          "ecs:StartTelemetrySession",
          "ecs:Submit*",
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource": "*"
    }
  ]
}
EOF
}

# ----------------------------------------------------------------------------------------------
# Security Groups

resource "aws_security_group" "this" {
  name        = "circles-${var.service_name}"
  description = "circles-${var.service_name}"
  vpc_id      = "${var.vpc_id}"
}

resource "aws_security_group_rule" "ingress" {
  count = "${length(var.ingress_rules)}"

  security_group_id = "${aws_security_group.this.id}"
  type              = "ingress"

  cidr_blocks = ["0.0.0.0/0"]
  description = "circles-${var.service_name}-${lookup(var.ingress_rules[count.index], "description")}"

  from_port = "${lookup(var.ingress_rules[count.index], "from_port")}"
  to_port   = "${lookup(var.ingress_rules[count.index], "to_port")}"
  protocol  = "${lookup(var.ingress_rules[count.index], "protocol")}"
}

resource "aws_security_group_rule" "egress" {
  security_group_id = "${aws_security_group.this.id}"
  type              = "egress"

  cidr_blocks = ["0.0.0.0/0"]
  description = "circles-${var.service_name}-egress}"

  from_port = "0"
  to_port   = "0"
  protocol  = "-1"
}
