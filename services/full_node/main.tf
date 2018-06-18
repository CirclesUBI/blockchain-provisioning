variable "vpc_id" {}
variable "subnet_id" {}
variable "availability_zone" {}
variable "ecs_cluster_name" {}
variable "ecs_cluster_id" {}
variable "ethstats" {}

locals {
  service_name = "fullnode"
  port         = 80
}

# ----------------------------------------------------------------------------------------------
# Task Definition
# ----------------------------------------------------------------------------------------------

data "template_file" "container_definitions" {
  template = "${file("${path.module}/containers.json")}"

  vars {
    log_group          = "${aws_cloudwatch_log_group.this.name}"
    port               = "${local.port}"
    service_name       = "${local.service_name}"
    ethstats           = "${var.ethstats}"
    ecr_repository_url = "${aws_ecr_repository.this.repository_url}"
  }
}

data "aws_iam_policy_document" "this" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
    ]

    resources = ["arn:aws:secretsmanager:eu-central-1:183869895864:secret:circles-ws-secret-nhzYC3"]
  }
}

# ----------------------------------------------------------------------------------------------
# Resources
# ----------------------------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "this" {
  name              = "circles-${local.service_name}"
  retention_in_days = "60"
}

resource "aws_ecr_repository" "this" {
  name = "circles-${local.service_name}"
}

# ----------------------------------------------------------------------------------------------
# Instance
# ----------------------------------------------------------------------------------------------

module "instance" {
  source = "../../modules/stateful_service"

  service_name = "${local.service_name}"

  instance_type = "t2.medium"

  dockerfile            = "services/full_node/Dockerfile"
  container_definitions = "${data.template_file.container_definitions.rendered}"
  iam_policy_json       = "${data.aws_iam_policy_document.this.json}"

  subnet_id         = "${var.subnet_id}"
  vpc_id            = "${var.vpc_id}"
  availability_zone = "${var.availability_zone}"
  ip_address        = "10.0.101.50"

  ecs_cluster_name   = "${var.ecs_cluster_name}"
  ecs_cluster_id     = "${var.ecs_cluster_id}"
  ecr_repository_url = "${aws_ecr_repository.this.repository_url}"

  ingress_rules = [
    {
      from_port   = "${local.port}"
      to_port     = "${local.port}"
      protocol    = "TCP"
      description = "web"
    },
  ]
}
