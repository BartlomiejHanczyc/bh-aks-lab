output "client_certificate" {
  value = azurerm_kubernetes_cluster.compute-main.kube_config[0].client_certificate
  sensitive = true
}

output "cluster_ca_certificate" {
  value = azurerm_kubernetes_cluster.compute-main.kube_config[0].cluster_ca_certificate
  sensitive = true
}

output "kube_config" {
  value = azurerm_kubernetes_cluster.compute-main.kube_config_raw
  sensitive = true
}

output "aks_host" {
  value = azurerm_kubernetes_cluster.compute-main.kube_config[0].host
  sensitive = true
}

output "aks_cluster_id" {
  value = azurerm_kubernetes_cluster.compute-main.id
}

output "client_key" {
  value = azurerm_kubernetes_cluster.compute-main.kube_config[0].client_key
  sensitive = true
}