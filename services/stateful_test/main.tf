variable "vpc_id" {}
variable "subnet_id" {}

variable "availability_zone" {}

locals {
  service_name = "stateful-test"
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "circles-${local.service_name}"
  retention_in_days = "60"
}

data "template_file" "docker_compose_yaml" {
  template = "${file("${path.module}/docker-compose.yaml")}"

  vars {
    log_group = "${aws_cloudwatch_log_group.this.name}"
  }
}

module "this" {
  source = "../../modules/stateful_service"

  service_name        = "${local.service_name}"
  docker_compose_yaml = "${data.template_file.docker_compose_yaml.rendered}"
  subnet_id           = "${var.subnet_id}"
  vpc_id              = "${var.vpc_id}"
  availability_zone   = "${var.availability_zone}"
  ip_address          = "10.0.101.50"

  extra_files = [
    {
      filename = "Dockerfile"
      content  = "${base64encode("${file("${path.module}/Dockerfile")}")}"
    },
    {
      filename = "genesis.json"
      content  = "${base64encode("${file("${path.root}/resources/genesis.json")}")}"
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
  ]
}
