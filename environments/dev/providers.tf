terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 5.1.0"
    }

    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "storage-rg"
    storage_account_name = "labstorageiac"
    container_name       = "tfstate"
    key                  = "dev.terraform.tfstate"

    use_azuread_auth = true
    use_cli          = true
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }

  subscription_id = "24718d55-5ec8-4959-aad6-9bcc1b825a75"
}

provider "azapi" {}

provider "kubernetes" {
  host = module.compute.aks_host

  cluster_ca_certificate = base64decode(
    module.compute.cluster_ca_certificate
  )

  client_certificate = base64decode(
    module.compute.client_certificate
  )

  client_key = base64decode(
    module.compute.client_key
  )
}