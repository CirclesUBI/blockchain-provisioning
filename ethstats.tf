data "template_file" "public_cloud_init" {
  template = "${file("${path.module}/ethstats-cloud-init.yaml")}"

  vars {
    get_secret_py = "${file("${path.root}/resources/get_secret.py")}"
  }
}

module "ethstats" {
  source = "modules/service"

  name = "ethstats"

  instance_profile_name = "${aws_iam_instance_profile.circles.name}"

  cloud_init = "${data.template_file.public_cloud_init.rendered}"

  vpc_id              = "${aws_vpc.circles.id}"
  subnet_id           = "${aws_subnet.circles.id}"
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

// -----------------------------------------------------------------------------
// OUTPUTS
// -----------------------------------------------------------------------------

output "ethstats" {
  value = "${module.ethstats.public_dns}:3000"
}
