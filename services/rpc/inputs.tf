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

variable "bootnode_ip" {
  description = "Bootnode IP address"
}

variable "bootnode_port" {
  description = "Bootnode port"
}

variable "bootnode_enode" {
  description = "enode for bootnode"
  default     = "976626fcad5feb994ab05ed984ad7d91bbea7d86e02a1ac04b7b0ef5fe3f1c09fc57cde95c0a6201c208469bccce228997946ebeedb828ddafcf03d20f982c8f"
}

variable "efs_id" {
  description = "id of the efs filesystem to use for blockchain storage"
}
