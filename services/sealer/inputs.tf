// Metatdat

variable "name" {
  description = "which name should be used for all generated aws resources"
}

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

variable "ethstats" {
  description = "hostname:port for ethstats"
}

variable "bootnode_ip" {
  description = "Bootnode IP address"
}

variable "bootnode_port" {
  description = "Bootnode port"
}

variable "bootnode_enode" {
  description = "enode for bootnode"
}

variable "efs_id" {
  description = "id of the efs filesystem to use for blockchain storage"
}

// Secrets

variable "secrets_key" {
  description = "Which secrets manager key should be used to retrieve the sealer account details"
}
