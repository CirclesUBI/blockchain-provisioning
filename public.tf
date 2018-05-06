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
        docker_compose_file = "${file("${path.module}/resources/public/docker-compose.yaml")}"
        genesis_json = "${file("${path.module}/resources/shared/genesis.json")}"
        get_secret_py = "${file("${path.module}/resources/shared/get_secret.py")}"
        docker_compose_version = "${var.docker_compose_version}"
        efs_id = "${aws_efs_file_system.circles.id}"
    }
}


// we use the template_cloudinit_config to gzip compress the cloud-init file (it's too big otherwise)
data "template_cloudinit_config" "public" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = "${data.template_file.public_cloud_init.rendered}"
  }
}

resource "aws_instance" "public" {
    instance_type = "t2.micro"
    ami = "${data.aws_ami.ec2-linux.id}"

    user_data = "${data.template_cloudinit_config.public.rendered}"

    iam_instance_profile = "${aws_iam_instance_profile.circles.name}"

    key_name = "circles-david"

    subnet_id = "${aws_subnet.circles.id}"
    vpc_security_group_ids = ["${aws_security_group.public.id}"]
    associate_public_ip_address = true

    tags {
        Name = "circles-public"
    }
}

// -----------------------------------------------------------------------------
// FIREWALL
// -----------------------------------------------------------------------------

resource "aws_security_group" "public" {
    name = "circles-public"
    vpc_id = "${aws_vpc.circles.id}"

    ingress {
        from_port   = "22"
        to_port     = "22"
        protocol    = "TCP"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = "${var.ethstats_port}"
        to_port     = "${var.ethstats_port}"
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

// -----------------------------------------------------------------------------
// OUTPUTS
// -----------------------------------------------------------------------------

output "ethstats" {
    value = "${aws_instance.public.public_dns}:3000"
}
