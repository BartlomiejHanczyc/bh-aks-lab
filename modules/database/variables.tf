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
      sku_name = string
      max_size_gb = number
  }))
}

variable "azuread_admin_username" {
    type = string
    default = "bartlomiej.hanczyc_gmail.com#EXT#@bartlomiejhanczycgmail.onmicrosoft.com"
}

variable "azuread_admin_object_id" {
  default = "5d7c73fe-b672-48aa-addd-0d65c8e4038c"
}