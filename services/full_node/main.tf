variable "vpc_id" {}
variable "subnet_id" {}
variable "availability_zone" {}
variable "ecs_cluster_name" {}
variable "ecs_cluster_id" {}

locals {
  service_name = "fullnode"
  port         = 8545
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "circles-${local.service_name}"
  retention_in_days = "60"
}

data "aws_iam_policy_document" "this" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
    ]

    resources = ["arn:aws:secretsmanager:eu-central-1:183869895864:secret:circles-ws-secret-nhzYC3"]
  }
}

data "template_file" "container_definitions" {
  template = "${file("${path.module}/service.json")}"

  vars {
    log_group = "${aws_cloudwatch_log_group.this.name}"
  }
}

module "instance" {
  source = "../../modules/stateful_service"

  service_name = "${local.service_name}"

  instance_type = "t2.medium"

  container_definitions = "${data.template_file.container_definitions.rendered}"
  iam_policy_json       = "${data.aws_iam_policy_document.this.json}"

  subnet_id         = "${var.subnet_id}"
  vpc_id            = "${var.vpc_id}"
  availability_zone = "${var.availability_zone}"
  ip_address        = "10.0.101.50"

  ecs_cluster_name = "${var.ecs_cluster_name}"
  ecs_cluster_id   = "${var.ecs_cluster_id}"
}
