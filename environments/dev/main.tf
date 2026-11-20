resource "azurerm_resource_provider_registration" "sql_registration" {
  name = "Microsoft.Sql"
}

resource "azurerm_resource_provider_registration" "network_registration" {
  name = "Microsoft.Network"
}

resource "azurerm_resource_provider_registration" "container_registration" {
  name = "Microsoft.ContainerService"
}

resource "azurerm_resource_provider_registration" "container_registry" {
  name = "Microsoft.ContainerRegistry"
}

module "networking" {
  source = "../../modules/networking"

  name                = "vnet-dev"
  environment         = "dev"
  resource_group_name = "rg-vnet-dev"

  location = "BelgiumCentral"

  address_space = ["10.0.0.0/16"]

  dns_servers = ["10.0.0.4"]

  subnets = {
    dev-main = {
      address_prefixes = ["10.0.1.0/24"]
    }
  }
}

module "database" {
  source = "../../modules/database"

  server_name         = "mssql-main"
  resource_group_name = "rg-sql"
  env_name            = "dev"
  location            = "BelgiumCentral"

  azuread_admin_username  = "bartlomiej.hanczyc_gmail.com#EXT#@bartlomiejhanczycgmail.onmicrosoft.com"
  azuread_admin_object_id = "5d7c73fe-b672-48aa-addd-0d65c8e4038c"

  databases = {
    sql-db-main = {
      sku_name    = "S0"
      max_size_gb = "2"
    }
  }
}

module "compute" {
  source = "../../modules/compute"

  cluster_name        = "main-cluster"
  resource_group_name = "rg-compute-main"
  location            = "BelgiumCentral"
  env_name            = "dev"
  acr_name            = "bhazureakslabacr"
}

module "key_vault" {
  source = "../../modules/key_vault"

  name = "main-key-vault"
  resource_group_name = "rg-key-vault-main"
  location = "BelgiumCentral"
  env_name = "dev"
}