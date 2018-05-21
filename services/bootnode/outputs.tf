output "public_ip" {
  value = "${module.bootnode.public_ip}"
}

output "port" {
  value = "${var.port}"
}
