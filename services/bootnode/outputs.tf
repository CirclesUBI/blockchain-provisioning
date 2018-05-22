output "port" {
  value = "${var.port}"
}

output "instance_id" {
  value = "${module.bootnode.instance_id}"
}
