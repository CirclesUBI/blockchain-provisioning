provider "aws" {
    region     = "eu-central-1"
}

data "template_file" "cloud_init" {
    template = "${file("${path.module}/cloud-init.yaml")}"

    vars {
        docker_compose_file = "${file("${path.module}/docker-compose.yaml")}"
        docker_compose_version = "1.20.1"
    }
}

resource "aws_instance" "circles" {
    // Ubuntu 16.04 LTS AMD64 EBS HVM
    ami           = "ami-7c412f13"
    instance_type = "t2.micro"

    associate_public_ip_address = true
    user_data     = "${data.template_file.cloud_init.rendered}"
    vpc_security_group_ids = ["${aws_security_group.allow_all.id}"]
}

resource "aws_security_group" "allow_all" {
    name = "allow_all"

    ingress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}
