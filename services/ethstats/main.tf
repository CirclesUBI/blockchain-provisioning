data "template_file" "cloud_config" {
  template = "${file("${path.module}/cloud-config.yaml")}"

  vars {
    ethstats_port = "${var.ethstats_port}"
  }
}

module "ethstats" {
  source = "../base"

  name = "ethstats"

  instance_profile_name = "${var.instance_profile_name}"

  cloud_config = "${data.template_file.cloud_config.rendered}"

  vpc_id              = "${var.vpc_id}"
  subnet_id           = "${var.subnet_id}"

  ingress_rules = [
    {
      from_port   = "${var.ethstats_port}"
      to_port     = "${var.ethstats_port}"
      protocol    = "TCP"
      description = "ethstats"
    },
  ]
}
