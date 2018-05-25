// -----------------------------------------------------------------------------
// Defines the explorer node
//
// The explorer runs an instance of the etherchain light block explorer
// -----------------------------------------------------------------------------

data "template_file" "ethstats_json" {
  template = "${file("${path.module}/ethstats.json")}"

  vars {
    ethstats = "${var.ethstats}"
  }
}

data "template_file" "dockerfile" {
  template = "${file("${path.module}/Dockerfile")}"

  vars {
    bootnode_enode = "${var.bootnode_enode}"
    bootnode_ip = "${var.bootnode_ip}"
    bootnode_port = "${var.bootnode_port}"
  }
}

data "template_file" "cloud_config" {
  template = "${file("${path.module}/cloud-config.yaml")}"

  vars {
    chainspec_json = "${file("${path.root}/resources/chainspec.json")}"
    dockerfile = "${data.template_file.dockerfile.rendered}"
    ethstats_json = "${data.template_file.ethstats_json.rendered}"
    parity_port = "${var.parity_port}"
    explorer_port = "${var.explorer_port}"
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
      from_port   = "${var.parity_port}"
      to_port     = "${var.parity_port}"
      protocol    = "TCP"
      description = "parity"
    },
    {
      from_port   = "${var.parity_port}"
      to_port     = "${var.parity_port}"
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
