output "public_dns" {
  value = "${aws_instance.this.public_dns}"
}

output "public_ip" {
  value = "${aws_instance.this.public_ip}"
}
