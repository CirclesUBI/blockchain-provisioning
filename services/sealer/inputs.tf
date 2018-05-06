// IAM

variable "instance_profile_name" {
  description = "Which IAM instance profile should the instance use"
}

// Networking

variable "vpc_id" {
  description = "In which vpc should the instance be created"
}

variable "subnet_id" {
  description = "In which subnet should the instance be created"
}

// App config

variable "geth_port" {
  description = "Port to expose geth on"
  default     = 30303
}

variable "ethstats_dns" {
  description = "dns name of ethstats instance"
}

variable "efs_id" {
  description = "id of the efs filesystem to use for blockchain storage"
}
