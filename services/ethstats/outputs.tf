output "public_dns" {
  value = "${module.ethstats.public_dns}"
}

output "port" {
  value = "${var.ethstats_port}"
}
