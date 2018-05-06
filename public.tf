// -----------------------------------------------------------------------------
// Defines the public node
//
// The sealer node runs the following services (orchestrated w./ docker-compose)
//   - bootnode (service discovery)
//   - ethstats (monitoring)
//   - rpc / relay node (for communication w./ metamask & relay of new transactions to sealer)
// -----------------------------------------------------------------------------

data "template_file" "public_cloud_init" {
  template = "${file("${path.module}/resources/public/cloud-init.yaml")}"

  vars {
    docker_compose_file    = "${file("${path.module}/resources/public/docker-compose.yaml")}"
    genesis_json           = "${file("${path.module}/resources/shared/genesis.json")}"
    get_secret_py          = "${file("${path.module}/resources/shared/get_secret.py")}"
    docker_compose_version = "${var.docker_compose_version}"
    efs_id                 = "${aws_efs_file_system.circles.id}"
  }
}

module "public" {
  source = "service"

  name = "public"

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
  value = "${module.public.public_dns}:3000"
}
