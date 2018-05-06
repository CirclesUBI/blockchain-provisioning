// -----------------------------------------------------------------------------
// Defines the sealer node
//
// The sealer node is responsible for creating & signing new blocks
// -----------------------------------------------------------------------------

data "template_file" "cloud_init" {
  template = "${file("${path.module}/cloud-init.yaml")}"

  vars {
    genesis_json   = "${file("${path.root}/resources/genesis.json")}"
    get_secret_py  = "${file("${path.root}/resources/get_secret.py")}"
    geth_version   = "geth-linux-amd64-1.8.6-12683fec"
    geth_md5       = "46cdf19716d0614ec84b49c0e10a64ae"
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

  cloud_init = "${data.template_file.cloud_init.rendered}"

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
