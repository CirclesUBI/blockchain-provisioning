provider "aws" {
    region     = "eu-central-1"
}

// -----------------------------------------------------------------------------
// NETWORK
//
// Defines a VPC with a single publicly visible subnet
// -----------------------------------------------------------------------------

resource "aws_vpc" "circles" {
    cidr_block       = "10.0.0.0/16"
    enable_dns_support = true
    enable_dns_hostnames = true

    tags {
        Name = "circles"
    }
}

resource "aws_subnet" "circles" {
    vpc_id                  = "${aws_vpc.circles.id}"
    cidr_block              = "10.0.0.0/24"
    map_public_ip_on_launch = true
    availability_zone = "eu-central-1b"

    tags {
        Name = "subnet az 1a"
    }
}

resource "aws_internet_gateway" "circles" {
    vpc_id = "${aws_vpc.circles.id}"

    tags {
        Name = "internet gateway"
    }
}

resource "aws_route" "internet_access" {
    route_table_id         = "${aws_vpc.circles.main_route_table_id}"
    destination_cidr_block = "0.0.0.0/0"
    gateway_id             = "${aws_internet_gateway.circles.id}"
}

// -----------------------------------------------------------------------------
// LOAD BALANCER & SCALING GROUP
//
// Runs health checks and ensures that at least one node is always up + healthy
// Allows for rolling zero downtime deployments
// -----------------------------------------------------------------------------

resource "aws_elb" "elb_app" {
    name = "app-elb"

    listener {
        instance_port = 3000
        instance_protocol = "http"
        lb_port = 3000
        lb_protocol = "http"
    }

    health_check {
        healthy_threshold = 3
        unhealthy_threshold = 2
        timeout = 10
        target = "HTTP:3000/"
        interval = 30
    }

    idle_timeout = 60
    subnets         = ["${aws_subnet.circles.id}"]
    security_groups = ["${aws_security_group.allow_all.id}"]

    tags {
        Name = "app-elb"
    }
}

resource "aws_autoscaling_group" "circles" {
    name = "circles"

    max_size = 2
    min_size = 1

    desired_capacity = 1
    wait_for_elb_capacity = 1

    health_check_grace_period = 300
    health_check_type = "ELB"

    launch_configuration = "${aws_launch_configuration.circles.id}"

    load_balancers = ["${aws_elb.elb_app.id}"]
    vpc_zone_identifier = ["${aws_subnet.circles.id}"]

    lifecycle {
        create_before_destroy = true
    }

    tag {
        key = "Name"
        value = "circles-${count.index}"
        propagate_at_launch = true
    }
}

// -----------------------------------------------------------------------------
// NODE
//
// Defines a single burstable instance with docker & docker-compose installed.
// Runs docker-compose up after boot
// -----------------------------------------------------------------------------

data "aws_ami" "ubuntu" {
    most_recent = true

    filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
    }

    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }

    // official cannonical account id
    owners = ["099720109477"]
}

data "template_file" "cloud_init" {
    template = "${file("${path.module}/cloud-init.yaml")}"

    vars {
        docker_compose_file = "${file("${path.module}/docker-compose.yaml")}"
        docker_compose_version = "1.20.1"
    }
}

resource "aws_launch_configuration" "circles" {
    lifecycle { create_before_destroy = true }

    instance_type = "t2.micro"
    image_id = "${data.aws_ami.ubuntu.id}"

    security_groups = ["${aws_security_group.allow_all.id}"]
    user_data       = "${data.template_file.cloud_init.rendered}"
}

// -----------------------------------------------------------------------------
// SECURITY GROUPS
//
// Defines a single group that allows all incoming and outgoing connections
// -----------------------------------------------------------------------------

resource "aws_security_group" "allow_all" {
    name = "allow_all"
    vpc_id = "${aws_vpc.circles.id}"

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
