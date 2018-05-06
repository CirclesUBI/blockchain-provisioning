// Metadata

variable "name" {
  description = "Name for the service in the aws console"
}

// IAM

variable "instance_profile_name" {
  description = "Which IAM instance profile should the instance use"
}

// Provisioning

variable "cloud_init" {
  description = "cloud_init file to be applied on instance launch"
  default     = ""
}

// Networking

variable "vpc_id" {
  description = "In which vpc should the instance be created"
}

variable "subnet_id" {
  description = "In which subnet should the instance be created"
}

variable "associate_public_ip" {
  description = "Should the instance have a publicly accesible IP address"
}

variable "ingress_rules" {
  description = "List of ingress rules to create"
  default     = []
}
