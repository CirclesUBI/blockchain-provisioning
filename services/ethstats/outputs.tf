output "instance_id" {
  value = "${module.ethstats.instance_id}"
}

output "port" {
  value = "${var.ethstats_port}"
}
