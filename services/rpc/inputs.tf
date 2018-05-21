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

variable "rpc_port" {
  description = "Port to expose the geth json-rpc interface on"
  default     = 8545
}

variable "ethstats_ip" {
  description = "dns name of ethstats instance"
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

