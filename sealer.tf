// -----------------------------------------------------------------------------
// Defines the sealer node
//
// The sealer node is responsible for creating & signing new blocks
// -----------------------------------------------------------------------------

data "aws_ami" "ec2-linux" {
    most_recent = true

    filter {
        name = "name"
        values = ["amzn-ami-*-x86_64-gp2"]
    }

    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }

    filter {
        name = "owner-alias"
        values = ["amazon"]
    }
}

data "template_file" "sealer_cloud_init" {
    template = "${file("${path.module}/resources/sealer/cloud-init.yaml")}"

    vars {
        genesis_json = "${file("${path.module}/resources/shared/genesis.json")}"
        get_secret_py = "${file("${path.module}/resources/shared/get_secret.py")}"
        geth_version = "geth-linux-amd64-1.8.6-12683fec"
        geth_md5 = "46cdf19716d0614ec84b49c0e10a64ae"
        network_id = "46781"
        sealer_account = "e477eaddcb3d365061083f60f14a4cf4d2782f96"
        efs_id = "${aws_efs_file_system.circles.id}"
        ethstats_dns = "${aws_instance.public.public_dns}"
    }
}

// we use the template_cloudinit_config to gzip compress the cloud-init file (it's too big otherwise)
data "template_cloudinit_config" "sealer" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = "${data.template_file.sealer_cloud_init.rendered}"
  }
}

resource "aws_instance" "sealer" {
    instance_type = "t2.micro"
    ami = "${data.aws_ami.ec2-linux.id}"

    user_data = "${data.template_cloudinit_config.sealer.rendered}"

    key_name = "circles-david"

    iam_instance_profile = "${aws_iam_instance_profile.circles.name}"

    subnet_id = "${aws_subnet.circles.id}"
    vpc_security_group_ids = ["${aws_security_group.sealer.id}"]
    associate_public_ip_address = true

    tags {
        Name = "circles-sealer"
    }
}

// -----------------------------------------------------------------------------
// SECRETS
//
// Defines an IAM instance profile that allows the node to read a single secret
// from AWS secrets manager
// -----------------------------------------------------------------------------

resource "aws_iam_instance_profile" "circles" {
  name  = "circles-secrets"
  role = "${aws_iam_role.circles.name}"
}

resource "aws_iam_role" "circles" {
  name = "circles-secrets"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_policy_attachment" "circles" {
  name       = "circles-secrets"
  roles      = ["${aws_iam_role.circles.name}"]
  policy_arn = "${aws_iam_policy.circles.arn}"
}

resource "aws_iam_policy" "circles" {
    name = "circles-secrets"

    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "secretsmanager:GetSecretValue",
            "Resource": "arn:aws:secretsmanager:eu-central-1:574150460280:secret:circles-secrets-zr9x30"
        }
    ]
}
EOF
}

// -----------------------------------------------------------------------------
// FIREWALL
// -----------------------------------------------------------------------------

resource "aws_security_group" "sealer" {
    name = "circles-sealer"
    vpc_id = "${aws_vpc.circles.id}"

    ingress {
        from_port   = "22"
        to_port     = "22"
        protocol    = "TCP"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = "${var.geth_port}"
        to_port     = "${var.geth_port}"
        protocol    = "TCP"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = "${var.geth_port}"
        to_port     = "${var.geth_port}"
        protocol    = "UDP"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

// -----------------------------------------------------------------------------
// OUTPUTS
// -----------------------------------------------------------------------------

output "sealer" {
    value = "${aws_instance.sealer.public_dns}"
}
