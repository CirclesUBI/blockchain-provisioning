// -----------------------------------------------------------------------------
// Defines a persistant EFS volume used to store chain-data
// -----------------------------------------------------------------------------

resource "aws_efs_file_system" "circles" {
  performance_mode = "maxIO"

  lifecycle {
    prevent_destroy = false
  }

  tags {
    Name = "circles-efs"
  }
}

resource "aws_efs_mount_target" "circles" {
  file_system_id  = "${aws_efs_file_system.circles.id}"
  subnet_id       = "${local.public_subnet_id}"
  security_groups = ["${aws_security_group.circles_efs_mount_target.id}"]
}

resource "aws_security_group" "circles_efs_mount_target" {
  name   = "circles_efs_mount_target"
  vpc_id = "${module.vpc.vpc_id}"

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
