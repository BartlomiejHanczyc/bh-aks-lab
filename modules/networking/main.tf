resource "azurerm_resource_group" "vnet-rg" {
  name = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "virtual_network" {
  name = var.name
  location = azurerm_resource_group.vnet-rg.location
  resource_group_name = azurerm_resource_group.vnet-rg.name
  address_space = var.address_space
  dns_servers = var.dns_servers
}

resource "azurerm_subnet" "vnet_subnet" {
  for_each = var.subnets

  virtual_network_name = azurerm_virtual_network.virtual_network.name
  resource_group_name = azurerm_virtual_network.virtual_network.resource_group_name
  name = each.key
  address_prefixes = each.value.address_prefixes
}