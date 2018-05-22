output "instance_id" {
  value = "${module.rpc.instance_id}"
}

output "port" {
  value = "${var.rpc_port}"
}
