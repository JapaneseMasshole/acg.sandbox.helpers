terraform {

  #required_version = ">=0.12"
  
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "2.92.0"
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
}

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
}

resource "azurerm_public_ip" "pubip" {
    name = "pubip"
    location = data.azurerm_resource_group.rg.location
    resource_group_name = data.azurerm_resource_group.rg.name
    allocation_method = "Static"
    sku = "Standard"
    availability_zone   = "No-Zone"
}

resource "azurerm_network_interface" "nic01" {
    name = "nic01"
    location = data.azurerm_resource_group.rg.location
    resource_group_name = data.azurerm_resource_group.rg.name
    ip_configuration {
      name = "ipconfig01"
      subnet_id = azurerm_subnet.subnet01.id
      private_ip_address_allocation = "Dynamic"
      public_ip_address_id = azurerm_public_ip.pubip.id
    }
}

resource "azurerm_windows_virtual_machine" "example" {
  name                = "mywindowsvm"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  admin_password      = "P@ssword1234!"
  network_interface_ids = [
    azurerm_network_interface.nic01.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }
}