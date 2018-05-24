// -----------------------------------------------------------------------------
// EC2 Instance
//
// defines a t2.micro ec2 instance running on amazon linux with an attached
// security group
// -----------------------------------------------------------------------------

// Latest Amazon Linux 2 AMI
data "aws_ami" "ec2-linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
}

data "template_file" "cloudwatch_config" {
  template = "${file("${path.module}/cloudwatch.json")}"

  vars {
    log_group_name = "circles-${var.name}"
  }
}

data "template_file" "base_cloud_config" {
  template = "${file("${path.module}/cloud-config.yaml")}"

  vars {
    get_secret_py   = "${file("${path.module}/scripts/get_secret.py")}"
    install_geth_py = "${file("${path.module}/scripts/install_geth.py")}"
    cloudwatch_json = "${data.template_file.cloudwatch_config.rendered}"
  }
}

// compress cloud-init file
data "template_cloudinit_config" "this" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = "${data.template_file.base_cloud_config.rendered}"
    merge_type   = "list(append)+dict(recurse_array)+str()"
  }

  part {
    content_type = "text/cloud-config"
    content      = "${var.cloud_config}"
    merge_type   = "list(append)+dict(recurse_array)+str()"
  }
}

resource "aws_instance" "this" {
  instance_type = "t2.micro"
  ami           = "${data.aws_ami.ec2-linux.id}"

  user_data = "${data.template_cloudinit_config.this.rendered}"

  iam_instance_profile = "${var.instance_profile_name}"

  subnet_id                   = "${var.subnet_id}"
  vpc_security_group_ids      = ["${aws_security_group.this.id}"]

  tags {
    Name = "circles-${var.name}"
  }
}

// -----------------------------------------------------------------------------
// Firewall
// -----------------------------------------------------------------------------

resource "aws_security_group" "this" {
  name        = "${var.name}"
  description = "circles-${var.name} security group"
  vpc_id      = "${var.vpc_id}"
}

resource "aws_security_group_rule" "ingress" {
  count = "${length(var.ingress_rules)}"

  security_group_id = "${aws_security_group.this.id}"
  type              = "ingress"

  cidr_blocks = ["0.0.0.0/0"]
  description = "circles-${var.name}-${lookup(var.ingress_rules[count.index], "description")}"

  from_port = "${lookup(var.ingress_rules[count.index], "from_port")}"
  to_port   = "${lookup(var.ingress_rules[count.index], "to_port")}"
  protocol  = "${lookup(var.ingress_rules[count.index], "protocol")}"
}

resource "aws_security_group_rule" "egress" {
  security_group_id = "${aws_security_group.this.id}"
  type              = "egress"

  cidr_blocks = ["0.0.0.0/0"]
  description = "circles-${var.name}-egress}"

  from_port = "0"
  to_port   = "0"
  protocol  = "-1"
}
