variable "vpc_id" {}
variable "subnet_id" {}
variable "availability_zone" {}
variable "ecs_cluster" {}

locals {
  service_name = "fullnode"
  port         = 8545
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "circles-${local.service_name}"
  retention_in_days = "60"
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

module "full_node_instance" {
  source = "../../modules/stateful_service"

  service_name = "${local.service_name}"

  instance_type = "t2.medium"

  subnet_id         = "${var.subnet_id}"
  vpc_id            = "${var.vpc_id}"
  availability_zone = "${var.availability_zone}"
  ip_address        = "10.0.101.50"
}
