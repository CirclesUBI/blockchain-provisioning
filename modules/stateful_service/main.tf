// A stateful_service is a single ec2 with a dettachable EBS volume and network interface

# ----------------------------------------------------------------------------------------------
# inputs

variable "service_name" {}

variable "ecs_cluster_name" {}
variable "ecs_cluster_id" {}

variable "vpc_id" {}
variable "subnet_id" {}
variable "availability_zone" {}

variable "iam_policy_json" {}
variable "container_definitions" {}

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
# ECS Service

resource "aws_ecs_task_definition" "this" {
  family                = "circles-${var.service_name}"
  container_definitions = "${var.container_definitions}"

  volume {
    name      = "data"
    host_path = "/data"
  }
}

resource "aws_ecs_service" "this" {
  name            = "circles-${var.service_name}"
  cluster         = "${var.ecs_cluster_id}"
  task_definition = "${aws_ecs_task_definition.this.arn}"
  desired_count   = 1

  # iam_role        = "${aws_iam_role.service.arn}"
  # depends_on      = ["aws_iam_role_policy.service"]
}

resource "aws_iam_role" "service" {
  name               = "circles-${var.service_name}-service"
  assume_role_policy = "${data.aws_iam_policy_document.service_assume_role_policy.json}"
}

data "aws_iam_policy_document" "service_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "service" {
  name   = "circles-${var.service_name}-service"
  role   = "${aws_iam_role.service.id}"
  policy = "${var.iam_policy_json}"
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
# user data

data "template_file" "awslogs_conf" {
  template = "${file("${path.module}/awslogs.conf")}"

  vars {
    service_name = "${var.service_name}"
    dmesg        = "/var/log/dmesg"
    messages     = "/var/log/messages"
    cloud_init   = "/var/log/cloud-init-output.log"
    docker       = "/var/log/docker"
    ecs_agent    = "/var/log/ecs/ecs-agent.log"
    ecs_init     = "/var/log/ecs/ecs-init.log"
    ecs_audit    = "/var/log/ecs/audit.log"
  }
}

data "template_file" "cloud_config" {
  template = "${file("${path.module}/cloud-config.yaml")}"

  vars {
    awslogs_conf        = "${data.template_file.awslogs_conf.rendered}"
    attach_resources_py = "${file("${path.module}/attach_resources.py")}"
    eni_id              = "${aws_network_interface.this.id}"
    volume_id           = "${aws_ebs_volume.this.id}"
    ecs_cluster_name    = "${var.ecs_cluster_name}"
    service_name        = "${var.service_name}"
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
# Host IAM

resource "aws_iam_instance_profile" "this" {
  name = "circles-${var.service_name}-host"
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
  name               = "circles-${var.service_name}-host"
  assume_role_policy = "${data.aws_iam_policy_document.instance_assume_role_policy.json}"
}

resource "aws_iam_role_policy" "this" {
  name = "circles-${var.service_name}-host"
  role = "${aws_iam_role.this.id}"

  policy = "${data.aws_iam_policy_document.this.json}"
}

data "aws_iam_policy_document" "this" {
  # Attach Network Interface
  statement {
    actions = [
      "ec2:AttachNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
    ]

    resources = ["*"]
  }

  # Attach EBS volume
  statement {
    actions = [
      "ec2:AttachVolume",
      "ec2:DescribeVolumeAttribute",
      "ec2:DescribeVolumeStatus",
      "ec2:DescribeVolumes",
    ]

    resources = ["*"]
  }

  # Take snapshots
  statement {
    actions = [
      "ec2:CreateSnapshot",
      "ec2:DeleteSnapshot",
      "ec2:DescribeSnapshotAttribute",
      "ec2:DescribeSnapshots",
      "ec2:DescribeTags",
      "ec2:DescribeVolumeAttribute",
      "ec2:DescribeVolumeStatus",
      "ec2:DescribeVolumes",
      "ec2:ModifySnapshotAttribute",
      "ec2:ResetSnapshotAttribute",
      "ec2:CreateTags",
      "ec2:DeleteTags",
      "ec2:DescribeTags",
    ]

    resources = ["*"]
  }

  # Write cloudwatch logs
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
    ]

    resources = ["arn:aws:logs:*:*:*"]
  }

  # Run ECS tasks
  statement {
    actions = [
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
    ]

    resources = ["*"]
  }
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
