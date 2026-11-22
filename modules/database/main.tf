resource "azurerm_resource_group" "database-rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_mssql_server" "mssql_server" {
  name                = var.server_name
  location            = azurerm_resource_group.database-rg.location
  version             = "12.0"
  resource_group_name = var.resource_group_name

  azuread_administrator {
    login_username              = var.azuread_admin_username
    object_id                   = var.azuread_admin_object_id
    azuread_authentication_only = true
  }

  tags = {
    environment = var.env_name
  }
}

resource "azurerm_mssql_database" "mssql_db" {
  for_each = var.databases

  name         = each.key
  server_id    = azurerm_mssql_server.mssql_server.id
  collation    = "SQL_Latin1_General_CP1_CI_AS"
  license_type = "LicenseIncluded"
  max_size_gb  = each.value.max_size_gb
  sku_name     = each.value.sku_name

  storage_account_type = "Local"

  geo_backup_enabled = false

  lifecycle {
    prevent_destroy = false
  }
}