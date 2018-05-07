output "public_ip" {
  value = "${module.bootnode.public_ip}"
}

output "port" {
  value = "${var.port}"
}

output "public_dns" {
  value = "${module.bootnode.public_dns}"
}
