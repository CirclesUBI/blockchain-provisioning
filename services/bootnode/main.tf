// -----------------------------------------------------------------------------
// Defines the sealer node
//
// The sealer node is responsible for creating & signing new blocks
// -----------------------------------------------------------------------------

data "template_file" "cloud_config" {
  template = "${file("${path.module}/cloud-config.yaml")}"

  vars {
    geth_version   = "1.8.7"
    geth_md5       = "ef06f6b85c29737124a1b44f3c114d02"
    geth_commit    = "66432f38"
    port           = ":${var.port}"
  }
}

module "bootnode" {
  source = "../base"

  name = "bootnode"

  instance_profile_name = "${var.instance_profile_name}"

  cloud_config = "${data.template_file.cloud_config.rendered}"

  vpc_id              = "${var.vpc_id}"
  subnet_id           = "${var.subnet_id}"
  associate_public_ip = true

  ingress_rules = [
    {
      from_port   = "${var.port}"
      to_port     = "${var.port}"
      protocol    = "UDP"
      description = "geth"
    },
    {
      from_port   = "${var.port}"
      to_port     = "${var.port}"
      protocol    = "TCP"
      description = "geth"
    },
  ]
}
