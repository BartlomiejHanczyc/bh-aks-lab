resource "azurerm_resource_group" "rg-compute" {
  name = var.resource_group_name
  location = var.location
}

resource "azurerm_kubernetes_cluster" "compute-main" {
  name = var.cluster_name
  location = azurerm_resource_group.rg-compute.location
  resource_group_name = azurerm_resource_group.rg-compute.name
  dns_prefix = "kube-main"

  default_node_pool {
    name = "default"
    node_count = 1
    vm_size = "Standard_D2_v2"
  }

  node_provisioning_profile {
    default_node_pools = "Auto"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = var.env_name
  }
}

resource "azurerm_container_registry" "acr" {
  name = var.acr_name
  resource_group_name = azurerm_resource_group.rg-compute.name
  location = azurerm_resource_group.rg-compute.location
  sku = "Standard"
  admin_enabled = false
}

resource "azurerm_role_assignment" "cluster-to-azr" {
  principal_id = azurerm_kubernetes_cluster.compute-main.kubelet_identity[0].object_id
  role_definition_name = "AcrPull"
  scope = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}