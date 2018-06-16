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
// Debug
// -----------------------------------------------------------------------------
resource "aws_key_pair" "debug" {
  key_name   = "circles-debug"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDhhDFjm/ZOVN3j1a10ZLr8az2Kcg0uHKn4tOKLJx8vzBnetiLqr6VEWlEv/mOyxjhSr50RWUrweyJZMYmKu3uIZdhj8xlnpF+BrHbdP3YTNPupzONoE4Fz19GxFDh0eCYRINLiOun7DfFRSPx+QTl3sLLuivBvJg6bWUciDJ5I5OaXSVoRi/No+GW1+LH8L0zrSyEXOe7uVkkA9dz0yqw+Aciu6tJPZFVdHgYt6lA5UtNAjb9zTTId7wIeWp/IG1m24AEKQO7vs+YBQz2v4PKdf/vzXiq1Rwo1YvScTl1GnrP3nXJZmgjEmvg1ZDdpq+ywySTCwghwKCqo6rp36oXkL2buVBEQ/fti76R+9M+bAqWD1x6T/hRf6ia/wSZmeVC+a7SUD5yHAB1u5FgC6kOLvnInf4lI7Y7pL1zfgsmIU63dTE3WQa1lcchhqRP2XcuPwZy1U084yho11pLyisGLufwRrT+jRvf7ii/5Cw9BAH2oKrWqcdIpTBKAwZUtK5dap/Tzyv1/GNzPWoE3yTtrHK5c18fgpoYQ+Sutc55QnIZhqlioFMOgbzMYbVtUSD8MwXSLtXE9lwoCDoQAJfhmgIPDWZwtyJwF/qSbE4+S27SETobx8bAWmX0eAcIE++8OYcNHuvDYIHq7Ei6R6N0GBjF+cl7zmnfsC6YIrh03tw== davidterry@posteo.de"
}

// -----------------------------------------------------------------------------
// SERVICES
// -----------------------------------------------------------------------------

resource "aws_key_pair" "david" {
  key_name   = "david"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDhhDFjm/ZOVN3j1a10ZLr8az2Kcg0uHKn4tOKLJx8vzBnetiLqr6VEWlEv/mOyxjhSr50RWUrweyJZMYmKu3uIZdhj8xlnpF+BrHbdP3YTNPupzONoE4Fz19GxFDh0eCYRINLiOun7DfFRSPx+QTl3sLLuivBvJg6bWUciDJ5I5OaXSVoRi/No+GW1+LH8L0zrSyEXOe7uVkkA9dz0yqw+Aciu6tJPZFVdHgYt6lA5UtNAjb9zTTId7wIeWp/IG1m24AEKQO7vs+YBQz2v4PKdf/vzXiq1Rwo1YvScTl1GnrP3nXJZmgjEmvg1ZDdpq+ywySTCwghwKCqo6rp36oXkL2buVBEQ/fti76R+9M+bAqWD1x6T/hRf6ia/wSZmeVC+a7SUD5yHAB1u5FgC6kOLvnInf4lI7Y7pL1zfgsmIU63dTE3WQa1lcchhqRP2XcuPwZy1U084yho11pLyisGLufwRrT+jRvf7ii/5Cw9BAH2oKrWqcdIpTBKAwZUtK5dap/Tzyv1/GNzPWoE3yTtrHK5c18fgpoYQ+Sutc55QnIZhqlioFMOgbzMYbVtUSD8MwXSLtXE9lwoCDoQAJfhmgIPDWZwtyJwF/qSbE4+S27SETobx8bAWmX0eAcIE++8OYcNHuvDYIHq7Ei6R6N0GBjF+cl7zmnfsC6YIrh03tw== davidterry@posteo.de"
}

resource "aws_ecs_cluster" "circles" {
  name = "circles"
}

resource "aws_ecr_repository" "circles" {
  name = "circles"
}

module "full_node" {
  source            = "services/full_node"
  subnet_id         = "${local.public_subnet_id}"
  vpc_id            = "${module.vpc.vpc_id}"
  availability_zone = "${var.availability_zone}"
  ecs_cluster_name  = "${aws_ecs_cluster.circles.name}"
  ecs_cluster_id    = "${aws_ecs_cluster.circles.id}"
  ecr_repository    = "${aws_ecr_repository.circles.registry_id}"
}

module "ethstats" {
  source = "services/ethstats"

  instance_profile_name = "${aws_iam_instance_profile.ethstats.name}"
  vpc_id                = "${module.vpc.vpc_id}"
  subnet_id             = "${local.public_subnet_id}"
}

module "bootnode" {
  source = "services/bootnode"

  instance_profile_name = "${aws_iam_instance_profile.bootnode.name}"
  vpc_id                = "${module.vpc.vpc_id}"
  subnet_id             = "${local.public_subnet_id}"
}

module "sealer1" {
  source = "services/sealer"
  name   = "sealer-1"

  secrets_key           = "circles-sealer-1"
  instance_profile_name = "${aws_iam_instance_profile.sealer1.name}"
  vpc_id                = "${module.vpc.vpc_id}"
  subnet_id             = "${local.private_subnet_id}"

  ethstats = "${module.ethstats.public_ip}:${module.ethstats.port}"
  efs_id   = "${aws_efs_file_system.circles.id}"

  bootnode_enode = "${var.bootnode_enode}"
  bootnode_port  = "${module.bootnode.port}"
  bootnode_ip    = "${module.bootnode.public_ip}"
}

module "sealer2" {
  source = "services/sealer"
  name   = "sealer-2"

  secrets_key           = "circles-sealer-2"
  instance_profile_name = "${aws_iam_instance_profile.sealer2.name}"
  vpc_id                = "${module.vpc.vpc_id}"
  subnet_id             = "${local.private_subnet_id}"

  ethstats = "${module.ethstats.public_ip}:${module.ethstats.port}"
  efs_id   = "${aws_efs_file_system.circles.id}"

  bootnode_enode = "${var.bootnode_enode}"
  bootnode_port  = "${module.bootnode.port}"
  bootnode_ip    = "${module.bootnode.public_ip}"
}

module "rpc" {
  source = "services/rpc"

  instance_profile_name = "${aws_iam_instance_profile.rpc.name}"
  vpc_id                = "${module.vpc.vpc_id}"
  subnet_id             = "${local.public_subnet_id}"

  ethstats = "${module.ethstats.public_ip}:${module.ethstats.port}"
  efs_id   = "${aws_efs_file_system.circles.id}"

  bootnode_enode = "${var.bootnode_enode}"
  bootnode_port  = "${module.bootnode.port}"
  bootnode_ip    = "${module.bootnode.public_ip}"
}

// -----------------------------------------------------------------------------
// OUTPUTS
// -----------------------------------------------------------------------------

output "ethstats" {
  value = "http://${aws_route53_record.ethstats.fqdn}:${module.ethstats.port}"
}

output "rpc" {
  value = "http://${aws_eip.rpc.public_ip}:${module.rpc.port}"
}

output "network_id" {
  value = "${var.network_id}"
}
