// -----------------------------------------------------------------------------
// Defines the sealer node
//
// The sealer node is responsible for creating & signing new blocks
// -----------------------------------------------------------------------------

data "template_file" "cloud_config" {
  template = "${file("${path.module}/cloud-config.yaml")}"

  vars {
    genesis_json   = "${file("${path.root}/resources/genesis.json")}"
    geth_version   = "1.8.7"
    geth_md5       = "ef06f6b85c29737124a1b44f3c114d02"
    geth_commit    = "66432f38"
    network_id     = "46781"
    sealer_account = "e477eaddcb3d365061083f60f14a4cf4d2782f96"
    efs_id         = "${var.efs_id}"
    ethstats_dns   = "${var.ethstats_dns}"
  }
}

module "sealer" {
  source = "../base"

  name = "sealer"

  instance_profile_name = "${var.instance_profile_name}"

  cloud_config = "${data.template_file.cloud_config.rendered}"

  vpc_id              = "${var.vpc_id}"
  subnet_id           = "${var.subnet_id}"
  associate_public_ip = true

  ingress_rules = [
    {
      from_port   = "${var.geth_port}"
      to_port     = "${var.geth_port}"
      protocol    = "TCP"
      description = "geth"
    },
    {
      from_port   = "${var.geth_port}"
      to_port     = "${var.geth_port}"
      protocol    = "UDP"
      description = "geth"
    },
  ]
}

// -----------------------------------------------------------------------------
// OUTPUTS
// -----------------------------------------------------------------------------

output "sealer" {
  value = "${module.sealer.public_dns}"
}
