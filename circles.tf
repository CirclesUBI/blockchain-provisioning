provider "aws" {
    region     = "eu-central-1"
}

data "template_file" "cloud_init" {
    template = "${file("${path.module}/cloud-init.yaml")}"

    vars {
        puppeth_public_key = "${aws_key_pair.puppeth.public_key}"
    }
}

resource "aws_instance" "circles" {
    // Ubuntu 16.04 LTS AMD64 EBS HVM
    ami           = "ami-7c412f13"
    instance_type = "t2.micro"

    user_data     = "${data.template_file.cloud_init.rendered}"

    vpc_security_group_ids = ["${aws_security_group.allow_all.id}"]
    associate_public_ip_address = true
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

resource "aws_key_pair" "puppeth" {
    key_name   = "puppeth"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCVuZgDKXQOcf6YFVMOrxi5L/6PjyWVEVv9ZPk2TJg7WFc1CKXpTzvQZehgXPlTLa/l2XvKPleMVHKm6teQmXSfv92WB55Glu+kfj5IeSrN0A8yArosIVfJki6Z+H5ne2QLl9Nl+SaQGfXpuHBxGs6vLdrGaCEtWZD3I51szv5oO7jel1pzduZV/a2iwOrLAECfEJa7dD7zVHnv8b6dLjeskBn/w1IbQA/8v68IQh8wbKA1mH3IOdNyXTofZWOEvEIqYJoIRc/FaNGJRLjx3hkMfuSd135nEGbnQQSTDyJtFwzvOT3/j3CAgR2gFkQW2VEOVMvpEKLBeEOZJYSrq/f3"
}
