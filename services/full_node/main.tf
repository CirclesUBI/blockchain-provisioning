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

module "static" {
  source       = "../../modules/static"
  service_name = "${local.service_name}"
}

data "template_file" "entrypoint" {
  vars {
    genesis_url      = "${module.static.genesis_url}"
    get_secret_url   = "${module.static.get_secret_url}"
    static_nodes_url = "${module.static.static_nodes_url}"
    service_name     = "${local.service_name}"
    ethstats         = "${var.ethstats}"
  }

  template = <<EOF
      apk add --no-cache python3 && pip3 install boto3
      curl -K $${get_secret_url} -o /get_secret.py

      python3 /get_secret.py \
        --name "circles-ws-secret" \
        --value "ws-secret" \
        --output /secrets/ws-secret

      if [ ! -d "/data/geth/chaindata" ]; then
        curl -K $${genesis_url} -o /genesis.json
        geth --datadir /data init /genesis.json
      fi

      curl -K $${static_nodes_url} -o /data/geth/static_nodes.json
      geth \
        --syncmode "full" \
        --datadir "/data" \
        --ethstats "$${service_name}:$(cat /secrets/ws-secret)@$${ethstats}" \
        --nodiscover
  EOF
}

data "template_file" "container_definitions" {
  template = "${file("${path.module}/containers.json")}"

  vars {
    log_group    = "${aws_cloudwatch_log_group.this.name}"
    port         = "${local.port}"
    service_name = "${local.service_name}"
    ethstats     = "${var.ethstats}"
    entrypoint   = "${jsonencode("${data.template_file.entrypoint.rendered}")}"
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

  ecs_cluster_name = "${var.ecs_cluster_name}"
  ecs_cluster_id   = "${var.ecs_cluster_id}"

  ingress_rules = [
    {
      from_port   = "${local.port}"
      to_port     = "${local.port}"
      protocol    = "TCP"
      description = "web"
    },
    {
      from_port   = "${local.port}"
      to_port     = "${local.port}"
      protocol    = "UDP"
      description = "web"
    },
  ]
}
