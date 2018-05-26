// A stateful_service is an ASG, EBS, and ENI as described in:
// https://techpunch.co.uk/development/how-to-perform-high-availability-deployments-of-stateful-applications-in-aws-zookeeper-edition

# ----------------------------------------------------------------------------------------------
# inputs

variable "service_name" {}

variable "dockerfile" {}

variable "docker_compose_yaml" {}
variable "subnet_id" {}
variable "vpc_id" {}

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

                "TerminationPolicies": ["OldestLaunchConfiguration", "OldestInstance"]
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
  }
}

data "template_file" "cloud_config" {
  template = "${file("${path.module}/cloud-config.yaml")}"

  vars {
    docker_compose_yaml = "${var.docker_compose_yaml}"
    dockerfile          = "${var.dockerfile}"
    awslogs_conf        = "${data.template_file.awslogs_conf.rendered}"
    awscli_conf         = "${file("${path.module}/awscli.conf")}"
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
# Security Groups

resource "aws_security_group" "this" {
  name        = "${var.service_name}"
  description = "circles-${var.service_name} security group"
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
