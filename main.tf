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
// DEBUG
// -----------------------------------------------------------------------------

resource "aws_key_pair" "david" {
  key_name   = "circles-david"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDhhDFjm/ZOVN3j1a10ZLr8az2Kcg0uHKn4tOKLJx8vzBnetiLqr6VEWlEv/mOyxjhSr50RWUrweyJZMYmKu3uIZdhj8xlnpF+BrHbdP3YTNPupzONoE4Fz19GxFDh0eCYRINLiOun7DfFRSPx+QTl3sLLuivBvJg6bWUciDJ5I5OaXSVoRi/No+GW1+LH8L0zrSyEXOe7uVkkA9dz0yqw+Aciu6tJPZFVdHgYt6lA5UtNAjb9zTTId7wIeWp/IG1m24AEKQO7vs+YBQz2v4PKdf/vzXiq1Rwo1YvScTl1GnrP3nXJZmgjEmvg1ZDdpq+ywySTCwghwKCqo6rp36oXkL2buVBEQ/fti76R+9M+bAqWD1x6T/hRf6ia/wSZmeVC+a7SUD5yHAB1u5FgC6kOLvnInf4lI7Y7pL1zfgsmIU63dTE3WQa1lcchhqRP2XcuPwZy1U084yho11pLyisGLufwRrT+jRvf7ii/5Cw9BAH2oKrWqcdIpTBKAwZUtK5dap/Tzyv1/GNzPWoE3yTtrHK5c18fgpoYQ+Sutc55QnIZhqlioFMOgbzMYbVtUSD8MwXSLtXE9lwoCDoQAJfhmgIPDWZwtyJwF/qSbE4+S27SETobx8bAWmX0eAcIE++8OYcNHuvDYIHq7Ei6R6N0GBjF+cl7zmnfsC6YIrh03tw== davidterry@posteo.de"
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

module "sealer" {
  source = "services/sealer"

  instance_profile_name = "${aws_iam_instance_profile.sealer.name}"
  vpc_id                = "${aws_vpc.circles.id}"
  subnet_id             = "${aws_subnet.circles.id}"

  ethstats_ip = "${module.ethstats.public_ip}"
  efs_id       = "${aws_efs_file_system.circles.id}"

  bootnode_port = "${module.bootnode.port}"
  bootnode_ip   = "${module.bootnode.public_ip}"
}

module "rpc" {
  source = "services/rpc"

  instance_profile_name = "${aws_iam_instance_profile.rpc.name}"
  vpc_id                = "${aws_vpc.circles.id}"
  subnet_id             = "${aws_subnet.circles.id}"

  ethstats_ip = "${module.ethstats.public_ip}"
  efs_id       = "${aws_efs_file_system.circles.id}"

  bootnode_port = "${module.bootnode.port}"
  bootnode_ip   = "${module.bootnode.public_ip}"
}

// -----------------------------------------------------------------------------
// OUTPUTS
// -----------------------------------------------------------------------------

output "ethstats" {
  value = "http://${module.ethstats.public_ip}:${module.ethstats.port}"
}

output "rpc" {
  value = "http://${module.rpc.public_ip}:${module.rpc.port}"
}

output "sealer" {
  value = "${module.sealer.public_ip}"
}

output "bootnode" {
  value = "${module.bootnode.public_ip}"
}
