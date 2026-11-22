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

resource "azapi_update_resource" "aks_gateway_api" {
    type = "Microsoft.ContainerService/managedClusters@2025-10-01"
    resource_id = var.aks_cluster_id

    body = {
      properties = {
        ingressProfile = {
          gatewayAPI = {
          installation = "Standard"
        },
        webAppRouting = {
          gatewayAPIImplementations = {
            appRoutingIstio = {
              mode = "Enabled"
            }
          }
        }
        }
      }
    }
}

resource "kubernetes_manifest" "api_gateway" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind = "Gateway"

    metadata = {
      name = "api-gateway"
      namespace = "aks-lab"
    }

    spec = {
      gatewayClassName = "approuting-istio"

      listeners = [
        {
          name = "http"
          protocol = "HTTP"
          port = "80"

          allowedRoutes = {
            namespaces = {
              from = "All"
            }
          }
        }
      ]
    }
  }

  depends_on = [azapi_update_resource.aks_gateway_api]
}