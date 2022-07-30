variable "resource_group_name" {
  type       = string
  default = ""
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