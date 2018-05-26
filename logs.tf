resource "aws_cloudwatch_log_group" "dmesg" {
  name              = "/var/log/dmesg"
  retention_in_days = "60"
}

resource "aws_cloudwatch_log_group" "messages" {
  name              = "/var/log/messages"
  retention_in_days = "60"
}

resource "aws_cloudwatch_log_group" "cloud_init_output" {
  name              = "/var/log/cloud-init-output.log"
  retention_in_days = "60"
}

resource "aws_cloudwatch_log_group" "docker" {
  name              = "/var/log/docker"
  retention_in_days = "60"
}
