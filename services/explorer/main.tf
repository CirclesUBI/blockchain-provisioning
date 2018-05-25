// -----------------------------------------------------------------------------
// Defines the explorer node
//
// The explorer runs an instance of the etherchain light block explorer
// -----------------------------------------------------------------------------

data "template_file" "cloud_config" {
  template = "${file("${path.module}/cloud-config.yaml")}"

  vars {
    docker_compose = "${file("${path.module}/docker-compose.yaml")}"
    bootnode_address = "${var.bootnode_ip}:${var.bootnode_port}"
    ethstats_address = "${var.ethstats}"
    efs_id = "${var.efs_id}"
    explorer_port = "${var.explorer_port}"
    genesis_json = "${file("${path.root}/resources/genesis.json")}"
  }
}

module "explorer" {
  source = "../base"

  name = "explorer"

  instance_profile_name = "${var.instance_profile_name}"

  cloud_config = "${data.template_file.cloud_config.rendered}"

  vpc_id              = "${var.vpc_id}"
  subnet_id           = "${var.subnet_id}"

  ingress_rules = [
    {
      from_port   = "${var.geth_port}"
      to_port     = "${var.geth_port}"
      protocol    = "TCP"
      description = "parity"
    },
    {
      from_port   = "${var.geth_port}"
      to_port     = "${var.geth_port}"
      protocol    = "UDP"
      description = "parity"
    },
    {
      from_port   = "${var.explorer_port}"
      to_port     = "${var.explorer_port}"
      protocol    = "TCP"
      description = "parity"
    },
  ]
}
