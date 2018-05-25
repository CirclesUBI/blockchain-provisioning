output "port" {
  value = "${var.port}"
}

output "instance_id" {
  value = "${module.bootnode.instance_id}"
}

output "public_ip" {
  value = "${module.bootnode.public_ip}"
}
