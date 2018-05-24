// -----------------------------------------------------------------------------
// VARIABLES
// -----------------------------------------------------------------------------

variable "region" {
  default = "eu-central-1"
}

variable "availability_zone" {
  default = "eu-central-1a"
}

// -----------------------------------------------------------------------------
// SERVICES
// -----------------------------------------------------------------------------

module "ethstats" {
  source = "services/ethstats"

  instance_profile_name = "${aws_iam_instance_profile.ethstats.name}"
  vpc_id                = "${aws_vpc.circles.id}"
  subnet_id             = "${aws_subnet.circles.id}"
}

module "bootnode" {
  source = "services/bootnode"

  instance_profile_name = "${aws_iam_instance_profile.bootnode.name}"
  vpc_id                = "${aws_vpc.circles.id}"
  subnet_id             = "${aws_subnet.circles.id}"
}

module "sealer1" {
  source = "services/sealer"
  name = "sealer-1"

  secrets_key = "circles-sealer-1"
  instance_profile_name = "${aws_iam_instance_profile.sealer1.name}"
  vpc_id                = "${aws_vpc.circles.id}"
  subnet_id             = "${aws_subnet.circles.id}"

  ethstats_ip = "${module.ethstats.public_ip}"
  efs_id       = "${aws_efs_file_system.circles.id}"

  bootnode_enode = "${var.bootnode_enode}"
  bootnode_port = "${module.bootnode.port}"
  bootnode_ip   = "${aws_eip.bootnode.public_ip}"
}

module "sealer2" {
  source = "services/sealer"
  name = "sealer-2"

  secrets_key = "circles-sealer-2"
  instance_profile_name = "${aws_iam_instance_profile.sealer2.name}"
  vpc_id                = "${aws_vpc.circles.id}"
  subnet_id             = "${aws_subnet.circles.id}"

  ethstats_ip = "${module.ethstats.public_ip}"
  efs_id       = "${aws_efs_file_system.circles.id}"

  bootnode_enode = "${var.bootnode_enode}"
  bootnode_port = "${module.bootnode.port}"
  bootnode_ip   = "${aws_eip.bootnode.public_ip}"
}

module "rpc" {
  source = "services/rpc"

  instance_profile_name = "${aws_iam_instance_profile.rpc.name}"
  vpc_id                = "${aws_vpc.circles.id}"
  subnet_id             = "${aws_subnet.circles.id}"

  ethstats_ip = "${module.ethstats.public_ip}"
  efs_id       = "${aws_efs_file_system.circles.id}"

  bootnode_enode = "${var.bootnode_enode}"
  bootnode_port = "${module.bootnode.port}"
  bootnode_ip   = "${aws_eip.bootnode.public_ip}"
}

// -----------------------------------------------------------------------------
// OUTPUTS
// -----------------------------------------------------------------------------

output "ethstats" {
  value = "http://${module.ethstats.public_ip}:${module.ethstats.port}"
}

output "rpc" {
  value = "http://${aws_eip.rpc.public_ip}:${module.rpc.port}"
}
