data "template_file" "cloud_init" {
  template = "${file("${path.module}/cloud-init.yaml")}"

  vars {
    get_secret_py = "${file("${path.root}/resources/get_secret.py")}"
  }
}

module "ethstats" {
  source = "../base"

  name = "ethstats"

  instance_profile_name = "${var.instance_profile_name}"

  cloud_init = "${data.template_file.cloud_init.rendered}"

  vpc_id              = "${var.vpc_id}"
  subnet_id           = "${var.subnet_id}"
  associate_public_ip = true

  ingress_rules = [
    {
      from_port   = "${var.ethstats_port}"
      to_port     = "${var.ethstats_port}"
      protocol    = "TCP"
      description = "ethstats"
    },
  ]
}
