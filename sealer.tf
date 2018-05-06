// -----------------------------------------------------------------------------
// Defines the sealer node
//
// The sealer node is responsible for creating & signing new blocks
// -----------------------------------------------------------------------------

data "template_file" "sealer_cloud_init" {
  template = "${file("${path.module}/resources/sealer/cloud-init.yaml")}"

  vars {
    genesis_json   = "${file("${path.module}/resources/shared/genesis.json")}"
    get_secret_py  = "${file("${path.module}/resources/shared/get_secret.py")}"
    geth_version   = "geth-linux-amd64-1.8.6-12683fec"
    geth_md5       = "46cdf19716d0614ec84b49c0e10a64ae"
    network_id     = "46781"
    sealer_account = "e477eaddcb3d365061083f60f14a4cf4d2782f96"
    efs_id         = "${aws_efs_file_system.circles.id}"
    ethstats_dns   = "${module.public.public_dns}"
  }
}


module "sealer" {
  source = "service"

  name = "sealer"

  instance_profile_name = "${aws_iam_instance_profile.circles.name}"

  cloud_init = "${data.template_file.sealer_cloud_init.rendered}"

  vpc_id              = "${aws_vpc.circles.id}"
  subnet_id           = "${aws_subnet.circles.id}"
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
