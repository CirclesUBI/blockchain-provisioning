// Metadata

variable "name" {
  description = "Name for the service in the aws console"
}

// IAM

variable "instance_profile_name" {
  description = "Which IAM instance profile should the instance use"
}

// Provisioning

variable "cloud_config" {
  description = "cloud-config file to be applied on instance launch"
  default     = ""
}

// Networking

variable "vpc_id" {
  description = "In which vpc should the instance be created"
}

variable "subnet_id" {
  description = "In which subnet should the instance be created"
}

variable "ingress_rules" {
  description = "List of ingress rules to create"
  default     = []
}
