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
  features {}
  skip_provider_registration = "true"
}

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
    delegation {
      name = "mtk-delegation-01"

      service_delegation {
        name    = "Microsoft.Web/serverFarms"
        actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    }
}

/*
resource "azurerm_network_security_group" "nsg" {
        name = "NSG01"
        location = data.azurerm_resource_group.rg.location
        resource_group_name = data.azurerm_resource_group.rg.name
        security_rule {
          name                       = "RDP"
          priority                   = 200
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "3389"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        }
}
resource "azurerm_subnet_network_security_group_association" "subnet_nsg" {
  subnet_id                 = azurerm_subnet.subnet01.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}*/

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