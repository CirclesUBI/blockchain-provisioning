// A stateful_service is an ASG, EBS, and ENI as described in:
// https://techpunch.co.uk/development/how-to-perform-high-availability-deployments-of-stateful-applications-in-aws-zookeeper-edition

# ----------------------------------------------------------------------------------------------
# inputs

variable "service_name" {}

variable "dockerfile" {}

variable "docker_compose_yaml" {}
variable "subnet_id" {}
variable "vpc_id" {}

variable "availability_zone" {}

variable "ip_address" {}

variable "ingress_rules" {
  type = "list"
}

# ----------------------------------------------------------------------------------------------
# ASG

resource "aws_cloudformation_stack" "this" {
  name = "circles-${var.service_name}-asg"

  template_body = <<EOF
{
    "Resources": {
        "asg": {
            "Type": "AWS::AutoScaling::AutoScalingGroup",
            "Properties": {
                "LaunchConfigurationName": "${aws_launch_configuration.this.name}",

                "MaxSize": "1",
                "MinSize": "0",
                "DesiredCapacity": "1",

                "HealthCheckType": "EC2",

                "LoadBalancerNames": [],
                "VPCZoneIdentifier": ["${var.subnet_id}"],

                "TerminationPolicies": ["OldestLaunchConfiguration", "OldestInstance"],

                "Tags": [
                  {
                    "Key" : "Name",
                    "Value" : "circles-${var.service_name}",
                    "PropagateAtLaunch" : "true"
                  },
                  {
                    "Key" : "instance_eni_id",
                    "Value" : "${aws_network_interface.this.id}",
                    "PropagateAtLaunch" : "true"
                  },
                  {
                    "Key" : "instance_volume",
                    "Value" : "${aws_ebs_volume.this.id}",
                    "PropagateAtLaunch" : "true"
                  }
                ]
            },
            "UpdatePolicy": {
                "AutoScalingRollingUpdate": {
                    "MinInstancesInService": "0",
                    "MaxBatchSize": "1",
                    "PauseTime": "PT0S",
                    "SuspendProcesses" : [
                      "HealthCheck",
                      "ReplaceUnhealthy",
                      "AZRebalance",
                      "AlarmNotification",
                      "ScheduledActions"
                    ]
                }
            }
        }
    }
}
EOF
}

resource "aws_launch_configuration" "this" {
  name_prefix = "circles-${var.service_name}-"

  instance_type        = "t2.micro"
  image_id             = "${data.aws_ami.ecs_optimized.id}"
  iam_instance_profile = "${aws_iam_instance_profile.this.name}"

  security_groups             = ["${aws_security_group.this.id}"]
  associate_public_ip_address = "true"

  user_data = "${data.template_file.cloud_config.rendered}"

  key_name = "david"

  lifecycle {
    create_before_destroy = true
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
    # include the subnet id to force terraform to recognise the dependency on the subnet
    # see: https://github.com/terraform-providers/terraform-provider-aws/issues/655
    Subnet = "${var.subnet_id}"

    Name = "circles-${var.service_name}"
  }
}

# ----------------------------------------------------------------------------------------------
# Static IP

resource "aws_network_interface" "this" {
  subnet_id       = "${var.subnet_id}"
  private_ips     = ["${var.ip_address}"]
  security_groups = ["${aws_security_group.this.id}"]
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
    docker_compose_yaml = "${var.docker_compose_yaml}"
    dockerfile          = "${var.dockerfile}"
    awslogs_conf        = "${data.template_file.awslogs_conf.rendered}"
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
  name               = "circles-${var.service_name}-instance-role"
  assume_role_policy = "${data.aws_iam_policy_document.instance_assume_role_policy.json}"
}

resource "aws_iam_role_policy" "cloudwatch_logs" {
  name = "circles-${var.service_name}-cloudwatch-logs"
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

# ----------------------------------------------------------------------------------------------
# IAM

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
