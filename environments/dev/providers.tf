terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 5.1.0"
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
  features {}

  subscription_id = "24718d55-5ec8-4959-aad6-9bcc1b825a75"
}