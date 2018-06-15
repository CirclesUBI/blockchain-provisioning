variable "vpc_id" {}
variable "subnet_id" {}

variable "availability_zone" {}

variable "network_id" {}
variable "ethstats" {}
variable "bootnode" {}

locals {
  service_name = "fullnode"
  port         = 8545
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "circles-${local.service_name}"
  retention_in_days = "60"
}

data "template_file" "dockerfile" {
  template = "${file("${path.module}/Dockerfile")}"

  vars {
    network_id   = "${var.network_id}"
    ethstats     = "${var.ethstats}"
    bootnode     = "${var.bootnode}"
    service_name = "${local.service_name}"
  }
}

data "template_file" "docker_compose_yaml" {
  template = "${file("${path.module}/docker-compose.yaml")}"

  vars {
    log_group = "${aws_cloudwatch_log_group.this.name}"
    port      = "${local.port}"
  }
}

resource "aws_iam_policy" "ethstats_ws_secret" {
  name = "circles-${local.service_name}-ws-secret"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "secretsmanager:GetSecretValue",
            "Resource": "arn:aws:secretsmanager:eu-central-1:183869895864:secret:circles-ws-secret-nhzYC3"
        }
    ]
}
EOF
}

module "this" {
  source = "../../modules/stateful_service"

  service_name        = "${local.service_name}"
  docker_compose_yaml = "${data.template_file.docker_compose_yaml.rendered}"
  subnet_id           = "${var.subnet_id}"
  vpc_id              = "${var.vpc_id}"
  availability_zone   = "${var.availability_zone}"
  ip_address          = "10.0.101.50"
  iam_policy          = "${aws_iam_policy.ethstats_ws_secret.arn}"
  instance_type       = "t2.medium"

  extra_files = [
    {
      filename = "Dockerfile"
      content  = "${base64encode("${data.template_file.dockerfile.rendered}")}"
    },
    {
      filename = "get_secret.py"
      content  = "${base64encode("${file("${path.root}/resources/get_secret.py")}")}"
    },
  ]

  ingress_rules = [
    {
      from_port   = "22"
      to_port     = "22"
      protocol    = "TCP"
      description = "ssh"
    },
    {
      from_port   = "${local.port}"
      to_port     = "${local.port}"
      protocol    = "TCP"
      description = "geth"
    },
    {
      from_port   = "${local.port}"
      to_port     = "${local.port}"
      protocol    = "UDP"
      description = "geth"
    },
  ]
}
