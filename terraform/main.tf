terraform {

  required_version = ">=0.12"
  
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
}

provider "azurerm" {
  features {}
  skip_provider_registration = "true"
}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

data "azurerm_storage_account" "storageacct" {
    name = var.storage_account_name
    resource_group_name = data.azurerm_resource_group.rg.name
}
