output "instance_id" {
  value = "${module.ethstats.instance_id}"
}

output "public_ip" {
  value = "${module.ethstats.public_ip}"
}

output "port" {
  value = "${var.ethstats_port}"
}
