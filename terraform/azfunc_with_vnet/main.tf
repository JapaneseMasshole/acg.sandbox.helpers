terraform {

  #required_version = ">=0.12"
  
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>3.51.0"
    }
  }
}

provider "azurerm" {
  features {
        key_vault {
          purge_soft_delete_on_destroy    = true
          recover_soft_deleted_key_vaults = true
        }
      }
  skip_provider_registration = "true"
}

data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "rg" {
    name = var.resource_group_name
}

data "azurerm_resources" "rootStorageAcct"{
  type = "Microsoft.Storage/storageAccounts"
  resource_group_name = data.azurerm_resource_group.rg.name
}

data "azurerm_storage_account" "storageacct" {
    name = data.azurerm_resources.rootStorageAcct.resources[0].name
    resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_key_vault" "example" {
  name                        = "kv-motoki-06"
  location                    = data.azurerm_resource_group.rg.location
  resource_group_name         = data.azurerm_resource_group.rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get",
    ]

    secret_permissions = [
      "Get",
    ]

    storage_permissions = [
      "Get",
    ]
  }
}

resource "azurerm_virtual_network" "vnet" {
    name = "VNET01"
    address_space = ["10.0.0.0/16"]
    location = data.azurerm_resource_group.rg.location
    resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet01" {
    name = "subnet01"
    address_prefixes = ["10.0.1.0/24"]
    virtual_network_name = azurerm_virtual_network.vnet.name
    resource_group_name = data.azurerm_resource_group.rg.name
    service_endpoints = ["Microsoft.KeyVault"]
    delegation {
      name = "mtk-delegation-01"

      service_delegation {
        name    = "Microsoft.Web/serverFarms"
        actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    }
}

resource "azurerm_public_ip" "pubip" {
    name = "pubip"
    location = data.azurerm_resource_group.rg.location
    resource_group_name = data.azurerm_resource_group.rg.name
    allocation_method = "Static"
    sku = "Standard"
    
}

resource "azurerm_public_ip_prefix" "example" {
  name                = "nat-gateway-publicIPPrefix"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  prefix_length       = 30

}

resource "azurerm_nat_gateway" "example" {
  name                    = "nat-Gateway"
  location                = data.azurerm_resource_group.rg.location
  resource_group_name     = data.azurerm_resource_group.rg.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
}

resource "azurerm_nat_gateway_public_ip_association" "example" {
  nat_gateway_id       = azurerm_nat_gateway.example.id
  public_ip_address_id = azurerm_public_ip.pubip.id
}

resource "azurerm_subnet_nat_gateway_association" "example" {
  subnet_id      = azurerm_subnet.subnet01.id
  nat_gateway_id = azurerm_nat_gateway.example.id
}

resource "azurerm_service_plan" "example" {
  name                = "example-app-service-plan"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  os_type = "Linux"
  sku_name = "P1v2"
}

resource "azurerm_linux_function_app" "example" {
  name                      = "mtk-example-function-app-01"
  location                  = data.azurerm_resource_group.rg.location
  resource_group_name       = data.azurerm_resource_group.rg.name
  service_plan_id       = azurerm_service_plan.example.id
  storage_account_name = data.azurerm_resources.rootStorageAcct.resources[0].name
  
  
  app_settings = {
    "WEBSITE_CONTENTAZUREFILECONNECTIONSTRING" = data.azurerm_storage_account.storageacct.primary_connection_string
    "WEBSITE_CONTENTSHARE"                     = data.azurerm_storage_account.storageacct.name
  }
  site_config {
    always_on = false
    application_stack {
      python_version             = "3.9"
    }
  }
  identity {
    type = "SystemAssigned"
  }

  depends_on = [
    azurerm_subnet.subnet01,
  ]
}

resource "azurerm_app_service_virtual_network_swift_connection" "example" {
  app_service_id       = azurerm_linux_function_app.example.id
  subnet_id            = azurerm_subnet.subnet01.id
}