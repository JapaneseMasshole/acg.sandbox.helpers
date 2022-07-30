variable "resource_group_name" {
  type       = string
  default = "1-08d7e6e2-playground-sandbox"
  description   = "Name of the existing resource group"
}
variable "network_address_space" {
  type = string
  default = "10.0.0.0/16"
}
variable "instance_count" {
  type = number
  default = 2
}
variable "subnet_count" {
  type = number
  default = 2
}
/*
variable "storage_account_name"{
  type = string
  description = "Name of the existing storage account name in the sandbox"
}*/