variable "bootnode_enode" {
    description = "Which enode should the sealer and rpc nodes connect to"
    default = "07d24a7a560c4b4011b71c94db03f48afba2bbb0d37b7a403d25bd86bb4d55e521b9f646371b99fdca194423a412d526613c991c493ca84af93e9c01e184f56a"
}

variable "domain" {
    description = "Which domain should the route53 records be created for"
    default = "circles-chain.com"
}
