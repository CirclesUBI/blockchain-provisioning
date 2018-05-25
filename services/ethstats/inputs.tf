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

variable "ethstats_port" {
  description = "Port to expose the ethstats service on"
  default     = 80
}
