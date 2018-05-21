output "public_ip" {
  value = "${module.rpc.public_ip}"
}

output "port" {
  value = "${var.rpc_port}"
}
