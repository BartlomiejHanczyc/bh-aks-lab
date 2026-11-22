variable "resource_group_name" {
  type = string
}

variable "server_name" {
  type = string
}

variable "env_name" {
  type = string
}

variable "location" {
  type = string
}

variable "databases" {
  type = map(object({
    sku_name    = string
    max_size_gb = number
  }))
}

variable "azuread_admin_username" {
  type = string
}

variable "azuread_admin_object_id" {
  type = string
}