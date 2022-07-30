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
  resource_group_name = data.azurerm_resource_group.rg.name
}

data "azurerm_storage_account" "storageacct" {
    name = data.azurerm_resources.rootStorageAcct.resources[0].name
    resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_virtual_network" "vnet" {
    name = "VNET01"
    address_space = [var.network_address_space]
    location = data.azurerm_resource_group.rg.location
    resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnets" {
    count = var.subnet_count
    name = "subnet-${count.index+1}"
    address_prefixes = [cidrsubnet(var.network_address_space, 8, count.index)]
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
  count = var.instance_count
  subnet_id                 = azurerm_subnet.subnets[(count.index % var.subnet_count)].id
  network_security_group_id = azurerm_network_security_group.nsg.id
}


resource "azurerm_public_ip" "pubips" {
    count = var.instance_count
    name = "pubip${count.index+1}"
    location = data.azurerm_resource_group.rg.location
    resource_group_name = data.azurerm_resource_group.rg.name
    allocation_method = "Static"
    sku = "Standard"
    availability_zone   = "No-Zone"
}

resource "azurerm_network_interface" "nics" {
    count = var.instance_count
    name = "nic${count.index+1}"
    location = data.azurerm_resource_group.rg.location
    resource_group_name = data.azurerm_resource_group.rg.name
    ip_configuration {
      name = "ipconfig${count.index+1}"
      subnet_id = azurerm_subnet.subnets[(count.index % var.instance_count)].id
      private_ip_address_allocation = "Dynamic"
      public_ip_address_id = azurerm_public_ip.pubips[(count.index % var.instance_count)].id
    }
}

resource "azurerm_windows_virtual_machine" "example" {
  count = var.instance_count
  name                = "mywindowsvm${count.index+1}"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  admin_password      = "P@ssword1234!"
  network_interface_ids = [
    azurerm_network_interface.nics[(count.index % var.instance_count)].id,
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