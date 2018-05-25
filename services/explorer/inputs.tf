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

variable "parity_port" {
  description = "Which port should be opeened for parity ethereum network communication (UDP & TCP)"
  default = "30303"
}

variable "explorer_port" {
  description = "Which port should be used to serve the explorer"
  default = "80"
}

// App config

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
