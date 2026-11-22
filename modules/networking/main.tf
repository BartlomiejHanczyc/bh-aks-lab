terraform {
  required_providers {
    azapi = {
      source = "Azure/azapi"
    }
  }
}

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

resource "azurerm_dns_zone" "aks" {
  name = "bhazureakslab.com"
  resource_group_name = azurerm_resource_group.vnet-rg.name
}

resource "azurerm_dns_a_record" "api_gateway" {
  name = "api"
  zone_name = azurerm_dns_zone.aks.name
  resource_group_name = azurerm_resource_group.vnet-rg.name
  ttl = 300
  records = ["9.160.150.238"]
}

resource "azapi_update_resource" "aks_gateway_api" {
    type = "Microsoft.ContainerService/managedClusters@2026-09-01"
    resource_id = var.aks_cluster_id

    body = {
      properties = {
        ingressProfile = {
          gatewayAPI = {
          installation = "Standard"
        },
        webAppRouting = {
          enabled = true
          gatewayAPIImplementations = {
            appRoutingIstio = {
              mode = "Enabled"
            }
          }
        }
        }
      }
    }
    
    response_export_values = ["properties.ingressProfile"]
}