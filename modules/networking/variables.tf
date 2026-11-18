variable "name" {
  type = string
}

variable "location" {
  type = string
}

variable "address_space" {
  type = set(string)
}

variable "dns_servers" {
  type = list(string)
}

variable "subnets" {
  type = map(object({
    address_prefixes = list(string)
  }))
}

variable "environment" {
  type = string
}

variable "resource_group_name" {
  type = string
}